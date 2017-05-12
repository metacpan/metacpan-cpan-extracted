#include <bitset>
#include <map>
#include <list>
#include <vector>
#include <set>
#include <cstdint>
#include <queue>
#include <algorithm>
#include <iterator>
#include <utility>
#include <stack>
#include <deque>

extern "C"
{
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

using namespace std;

// TODO: more error handling when Perl API functions fail
// TODO: use a vector for lookup tables like `successors`
// TODO: exploit that a list rather than a sub can be used
//       to identify accepting configurations, the call_sv
//       and the associated array copying is a bottleneck

typedef UV            State;
typedef set<State>    States;
typedef UV            Label;
typedef size_t        StatesId;

template <class T>
class VectorBasedSet {
public:
  std::vector<bool>  included;
  std::vector<T> elements;
  bool empty() { return elements.empty(); };
  bool contains(const T& s) {
    return s < included.size() && included[s];
  }
  void insert(const T& s) {
    if (!contains(s)) {
      if (included.size() <= s) {
        included.resize(s + 1);
      }
      included[s] = true;
      elements.push_back(s);
    }
  };
  T& back() {
    return elements.back();
  }
  void pop_back() {
    auto back_element = back();
    included[back_element] = false;
    elements.pop_back();
  }
  void clear() {
    included.clear();
    elements.clear();
  }
};

void
add_all_reachable_and_self(
  VectorBasedSet<State>& todo,
  VectorBasedSet<State>& s,
  map<State, bool>& nullable,
  map<State, vector<State>>& successors) {

  for (auto i = s.elements.begin(); i != s.elements.end(); ++i) {
    if (!nullable[*i])
      continue;

    auto x = successors[*i];
    
    for (auto k = x.begin(); k != x.end(); ++k)
      todo.insert(*k);
  }

  while (!todo.empty()) {
    State current = todo.back();
    todo.pop_back();

    if (s.contains(current)) {
      continue;
    }

    s.insert(current);

    if (nullable[current]) {
      auto x = successors[current];
      
      for (auto i = x.begin(); i != x.end(); ++i)
        todo.insert(*i);
    }
  }
}

bool does_accept(SV* accept_sv, vector<State> s) {
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  
  for (auto i = s.begin(); i != s.end(); ++i) {
    mXPUSHs(newSVuv(*i));
  }

  PUTBACK;

  I32 count = call_sv(accept_sv, G_SCALAR);

  SPAGAIN;

  bool result = false;

  if (count == 1) {
    result = (bool)POPi;
  } else {
    warn("bad accept");
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}

class StatesBimap {
public:
  std::map<vector<State>, StatesId> s2id;
  std::vector<vector<State>> id2s;

  StatesBimap() {
    states_to_id(States());
  };
  
  StatesId states_to_id(const States& s) {
    vector<State> v;
    
    std::copy(s.begin(), s.end(),
      std::back_inserter(v));
    
    return states_to_id(v);
  }

  StatesId states_to_id(const vector<State>& s) {
    auto v = s;
    std::sort(v.begin(), v.end());
    
    if (s2id.find(v) == s2id.end()) {
      s2id[v] = id2s.size();
      id2s.push_back(v);
    }
    return s2id[v];
  }
  
  const vector<State>& id_to_states(StatesId id) {
    if (id >= id2s.size()) {
      warn("Programmer error looking up %u", id);
    }
    return id2s[id];
  }
};

map<size_t, HV*>
build_dfa(SV* accept_sv, AV* args) {

  typedef map<pair<StatesId, Label>, StatesId> Automaton;
  StatesBimap               m;
  VectorBasedSet<State>     sub_todo;

  // Input from Perl
  map<State, vector<State>> successors;
  map<State, bool>          nullable;
  map<State, Label>         label;
  map<size_t, States>       start_states;
  
  I32 args_len = av_len(args);

  for (int ix = 0; ix <= args_len; ++ix) {
    SV** current_svp = av_fetch(args, ix, 0);

    if (current_svp == NULL)
      croak("Bad arguments");

    SV* current_sv = (SV*)*current_svp;

    if (!( SvROK(current_sv) && SvTYPE(SvRV(current_sv)) == SVt_PVAV))
      croak("Bad arguments");

    AV* current_av = (AV*)SvRV(current_sv);

    // [vertex, label, nullable, in_start, successors...]

    if (av_len(current_av) < 3)
      croak("Bad arguments");

    SV** vertex_svp = av_fetch(current_av, 0, 0);
    SV** label_svp  = av_fetch(current_av, 1, 0);
    SV** null_svp   = av_fetch(current_av, 2, 0);
    SV** start_svp  = av_fetch(current_av, 3, 0);

    if (!(vertex_svp && label_svp && null_svp && start_svp))
      croak("Internal error");

    nullable[SvUV(*vertex_svp)] = SvTRUE(*null_svp);

    if (SvOK(*label_svp))
      label[SvUV(*vertex_svp)] = SvUV(*label_svp);


    if (!( SvROK(*start_svp) && SvTYPE(SvRV(*start_svp)) == SVt_PVAV))
      croak("Bad arguments");

    AV* start_av = (AV*)SvRV(*start_svp);
    I32 start_av_len = av_len(start_av);
    
    for (int k = 0; k <= start_av_len; ++k) {
      SV** item_svp  = av_fetch(start_av, k, 0);
      if (SvUV(*item_svp) == 0) {
        croak("Bad arguments (start vertex)");
      }
      start_states[SvUV(*item_svp)].insert(SvUV(*vertex_svp));
    }
    
    I32 current_av_len = av_len(current_av);

    for (int k = 4; k <= current_av_len; ++k) {
      SV** successor_svp = av_fetch(current_av, k, 0);
      
      if (!successor_svp)
        croak("Internal error");

      successors[SvUV(*vertex_svp)].push_back(SvUV(*successor_svp));
    }
  }

  VectorBasedSet<State>         sub_temp;
  set<StatesId>                 seen;
  list<StatesId>                todo;
  set<StatesId>                 final_states;
  Automaton                     automaton;
  map<StatesId, set<StatesId>>  predecessors;
  map<StatesId, bool>           accepting;
  
  for (auto s = start_states.begin(); s != start_states.end(); ++s) {
    States& start_state = s->second;

    sub_temp.clear();
  
    for (auto i = start_state.begin(); i != start_state.end(); ++i) {
      sub_temp.insert(*i);
    }

    add_all_reachable_and_self(sub_todo, sub_temp, nullable, successors);

    start_state.insert(sub_temp.elements.begin(), sub_temp.elements.end());

    auto startId = m.states_to_id(start_state);
    todo.push_front(startId);
  }

  while (!todo.empty()) {
    StatesId currentId = todo.front();
    todo.pop_front();

    if (seen.find(currentId) != seen.end()) {
      continue;
    }

    seen.insert(currentId);

    vector<State> current = m.id_to_states(currentId);

    if (accepting.find(currentId) == accepting.end()) {
      accepting[currentId] = does_accept(accept_sv, current);
    }

    if (accepting[currentId]) {
      final_states.insert(currentId);
    }

    map<Label, States> by_label;

    for (auto i = current.begin(); i != current.end(); ++i) {
      if (label.find(*i) == label.end())
        continue;
        
      by_label[label[*i]].insert(*i);
    }
    
    for (auto i = by_label.begin(); i != by_label.end(); ++i) {
      States destination;
      auto second = i->second;
      auto current_label = i->first;
      
      sub_temp.clear();
      
      for (auto j = second.begin(); j != second.end(); ++j) {
        auto x = successors[*j];
        for (auto k = x.begin(); k != x.end(); ++k) {
          sub_temp.insert(*k);
        }
      }
      
      add_all_reachable_and_self(sub_todo, sub_temp, nullable, successors);

      StatesId destinationId = m.states_to_id(sub_temp.elements);
      automaton[make_pair(currentId, current_label)] = destinationId;
      predecessors[destinationId].insert(currentId);
      todo.push_front(destinationId);
    }
  }

  set<StatesId>  reachable;
  list<StatesId> reachable_todo;

  std::copy(final_states.begin(), final_states.end(),
    std::front_inserter(reachable_todo));

  while (!reachable_todo.empty()) {
    StatesId current = reachable_todo.front();
    reachable_todo.pop_front();

    if (reachable.find(current) != reachable.end()) {
      continue;
    }

    reachable.insert(current);
    
    std::copy(predecessors[current].begin(),
      predecessors[current].end(),
      std::front_inserter(reachable_todo));
  }

  States sink;

  for (auto s = automaton.begin(); s != automaton.end(); /* */) {
    StatesId src = s->first.first;
    Label label  = s->first.second;
    StatesId dst = s->second;

    if (reachable.find(src) == reachable.end()) {
      vector<State> x = m.id_to_states(src);
      sink.insert(x.begin(), x.end());
      s = automaton.erase(s);
      continue;
    }

    if (reachable.find(dst) == reachable.end()) {
      vector<State> x = m.id_to_states(dst);
      sink.insert(x.begin(), x.end());
      s = automaton.erase(s);
      continue;
    }

    s++;
  }

  auto sinkId = m.states_to_id(sink);
  
  if (accepting.find(sinkId) == accepting.end()) {
    accepting[sinkId] = does_accept(accept_sv, m.id_to_states(sinkId));
  }

  seen.insert(sinkId);

  map<StatesId, size_t> state_map;
  state_map[sinkId] = 0;
  size_t state_next = 1 + start_states.size();
  
  map<StatesId, size_t> start_ix_to_state_map_id;
  
  for (auto s = start_states.begin(); s != start_states.end(); ++s) {
    auto startIx = s->first;
    auto state = s->second;
    auto startId = m.states_to_id(state);
    
    if (reachable.find(startId) == reachable.end()) {
      croak("start state %u unreachable", startIx);
    }
    
    if (state_map.find(startId) != state_map.end()) {
      // This happens when equivalent start states are passed to the
      // construction function.
    } else {
      state_map[startId] = startIx;
    }
  }

  // ...
  map<size_t, HV*> dfa;
  
  reachable.insert(sinkId);

  for (auto s = reachable.begin(); s != reachable.end(); ++s) {
    if (state_map.find(*s) == state_map.end()) {
      state_map[*s] = state_next++;
    }
  }

  map<size_t, StatesId> state_map_r;

  for (auto s = state_map.begin(); s != state_map.end(); ++s) {
    state_map_r[s->second] = s->first;
  }
  
  // If multiple start states are passed to the construction function and
  // they either are identical, or turn out to be equivalent once all the
  // epsilon-reachable states are added to them, mapping distinct states
  // to distinct numbers leaves out the duplicates. Since the API conven-
  // tion is that states 1..n in the generated DFA correspond to the 1..n
  // start state in the input, the duplicates have to be generated here.

  for (auto s = start_states.begin(); s != start_states.end(); ++s) {
    auto startIx = s->first;
    auto state = s->second;
    auto startId = m.states_to_id(state);
    state_map_r[startIx] = startId;
  }

  multimap<StatesId, HV*> id_to_hvs;
  
  for (auto s = state_map_r.begin(); s != state_map_r.end(); ++s) {
    
    HV* state_hv     = newHV();
    AV* combines_av  = newAV();
    SV* combines_rv  = newRV_noinc((SV*)combines_av);
    HV* next_over_hv = newHV();
    SV* next_over_rv = newRV_noinc((SV*)next_over_hv);

    auto he1 = hv_store(state_hv, "Accepts", 7, newSVuv(accepting[s->second]), 0);
    auto he2 = hv_store(state_hv, "Combines", 8, combines_rv, 0);
    auto he3 = hv_store(state_hv, "NextOver", 8, next_over_rv, 0);

    vector<State> x = m.id_to_states(s->second);

    for (auto k = x.begin(); k != x.end(); ++k) {
      av_push(combines_av, newSVuv(*k));
    }

    dfa[s->first] = state_hv;

    id_to_hvs.insert(make_pair(s->second, state_hv));
  }

  for (auto s = automaton.begin(); s != automaton.end(); ++s) {
    StatesId srcId  = s->first.first;
    Label label = s->first.second;
    StatesId dstId  = s->second;

    if (dfa.find(state_map[srcId]) == dfa.end()) {
      croak("...");
    }
    
    for (auto p = id_to_hvs.find(srcId); p != id_to_hvs.end(); ++p) {
      if (p->first != srcId)
        break;
        
      SV** next_over_svp = hv_fetch(p->second, "NextOver", 8, 0);
      
      if (!next_over_svp)
        croak("...");
        
      SV* label_sv = newSVuv(label);  
        
      HE* he = hv_store_ent((HV*)SvRV(*next_over_svp),
        label_sv, newSVuv(state_map[dstId]), 0);

      if (he == NULL) {
        warn("hv_store_ent failed");
        SvREFCNT_dec(label_sv);
      }
    }
  }
  
  return dfa;
}

MODULE = Algorithm::ConstructDFA::XS  PACKAGE = Algorithm::ConstructDFA::XS

void
_internal_construct_dfa_xs(accepts_sv, args_sv)
    SV* accepts_sv
    SV* args_sv
  PREINIT:
    AV* args;
  PPCODE:
    args = (AV*)SvRV(args_sv);

    PUTBACK;
    auto dfa = build_dfa(accepts_sv, args);
    SPAGAIN;

    for (auto i = dfa.begin(); i != dfa.end(); ++i) {
      mXPUSHs(newSVuv(i->first));
      mXPUSHs(newRV_noinc((SV*)(i->second)));
    }
