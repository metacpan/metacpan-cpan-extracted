#pragma once
#include <map>
#include <typeinfo>
#include <stdint.h>
#include <stddef.h>
#include <type_traits>

namespace panda {

namespace cast {
namespace helper {
    typedef std::map<intptr_t, ptrdiff_t> DynCastCacheMap;

    template <class DERIVED, class BASE>
    DynCastCacheMap& get_map () {
        thread_local DynCastCacheMap* map;
        if (!map) {
            thread_local DynCastCacheMap _map;
            map = &_map;
        }
        return *map;
    }

    const ptrdiff_t INCORRECT_PTRDIFF = sizeof(ptrdiff_t) == 4 ? 2147483647 : 9223372036854775807LL;
}
}

template <class DERIVED_PTR, class BASE>
DERIVED_PTR dyn_cast (BASE* obj) {
    using namespace cast::helper;
    using DERIVED = typename std::remove_pointer<DERIVED_PTR>::type;

    if (std::is_same<BASE,DERIVED>::value) return (DERIVED_PTR)((void*)obj);
    if (!obj) return NULL;

    intptr_t key = (intptr_t)typeid(*obj).name();
    auto&    map = get_map<DERIVED,BASE>();
    //auto& map = DynCastCache<DERIVED,BASE>::map;
    DynCastCacheMap::iterator it = map.find(key);
    if (it != map.end())
        return it->second != INCORRECT_PTRDIFF ? reinterpret_cast<DERIVED*>((char*)obj - it->second) : NULL;
    DERIVED* ret = dynamic_cast<DERIVED*>(obj);
    if (ret) map[key] = (char*)obj - (char*)ret;
    else map[key] = INCORRECT_PTRDIFF;
    return ret;
}

template <class DERIVED_REF, class BASE>
DERIVED_REF dyn_cast (BASE& obj) {
    using namespace cast::helper;
    using DERIVED = typename std::remove_reference<DERIVED_REF>::type;

    if (std::is_same<BASE,DERIVED>::value) return reinterpret_cast<DERIVED_REF>(obj);

    intptr_t key = (intptr_t)typeid(obj).name();
    auto&    map = get_map<DERIVED,BASE>();
    DynCastCacheMap::iterator it = map.find(key);
    if (it != map.end() && it->second != INCORRECT_PTRDIFF)
        return *(reinterpret_cast<DERIVED*>((char*)&obj - it->second));
    // dont cache fails, as exceptions are much slower than dynamic_cast, let it always fall here
    DERIVED& ret = dynamic_cast<DERIVED&>(obj);
    map[key] = (char*)&obj - (char*)&ret;
    return ret;
}

}
