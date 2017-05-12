package App::vaporcalc::Cmd::Subject::Help;
$App::vaporcalc::Cmd::Subject::Help::VERSION = '0.005004';
use Defaults::Modern;
use Moo;

method _subject { 'help' }
method _build_verb { 'show' }
with 'App::vaporcalc::Role::UI::Cmd';

has '+recipe' => (
  isa     => Any,
);


method _action_view { $self->_action_show }
method _action_show {
  my $topic = $self->params->get(0);
  my $str;
  unless ($topic) {
    $str = join "\n",
      "Commands can be entered as:",
      " [ <VERB> <SUBJECT> <PARAM> ] or [ <SUBJECT> <VERB> <PARAM> ]",
      " e.g.:  set nic base 100",
      "(Without a verb, most subjects will call 'view')",
      " recipe <view/save [PATH]/load [PATH]>",
      " target amount <view/set [ml]>",
      " flavor <view/set [tag] [% of total] [PG/VG]/del [tag]/clear>",
      " nic base <view/set [mg/ml]>",
      " nic target <view/set [mg/ml]>", 
      " nic type <view/set [PG/VG]>",
      " pg <view/set [% of total]>",
      " vg <view/set [% of total]>",
      " notes <view/clear/add [STR]/del [IDX]>"
  }
 
  $self->create_result(
    string => ($str || "No help found for '$topic'")
  )
}

1;

=for Pod::Coverage .*

=cut

