#include "test.h"
#include <panda/string_map.h>
#include <panda/string_set.h>
#include <panda/unordered_string_map.h>
#include <panda/unordered_string_set.h>

using namespace panda;
using namespace test;
using test::Allocator;

using String = panda::basic_string<char, std::char_traits<char>, Allocator<char>>;

const string_view key1  = "key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1key1";
const string_view key2  = "key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2key2";
const string_view val1  = "1111111111111111111111111111111111111111";
const string_view val2  = "22222222222222222222222222222222222222222222222222";
const string_view val3  = "333333333333333333333333333333333333333333333333333333333333";
const string_view nokey = "nokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokeynokey";

TEST_CASE("string_map", "[string_containers]") {
    string_map<String, string> c;
    c.emplace(key1, val1);
    c.emplace(key2, val2);
    get_allocs();

    SECTION("find") {
        REQUIRE(c.find(key1)->second == val1);
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("at") {
        REQUIRE(c.at(key1) == val1);
        REQUIRE(c.at(key2) == val2);
        REQUIRE_THROWS(c.at(nokey));
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 1);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE((it++)->second == val1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE((it++)->second == val2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("lower_bound") {
        REQUIRE(c.lower_bound("0")->second == val1);
        REQUIRE(c.lower_bound(key1)->second == val1);
        REQUIRE(c.lower_bound(nokey) == c.end());
    }

    SECTION("upper_bound") {
        REQUIRE(c.upper_bound("0")->second == val1);
        REQUIRE(c.upper_bound(key1)->second == val2);
        REQUIRE(c.upper_bound(key2) == c.end());
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 1);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(c.at(key2) == val2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("string_multimap", "[string_containers]") {
    string_multimap<String, string> c;
    c.emplace(key1, val1);
    c.emplace(key2, val2);
    c.emplace(key1, val3);
    get_allocs();

    SECTION("find") {
        REQUIRE(c.find(key1)->second == val1);
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 2);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE((it++)->second == val1);
        REQUIRE((it++)->second == val3);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE((it++)->second == val2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("lower_bound") {
        REQUIRE(c.lower_bound("0")->second == val1);
        REQUIRE(c.lower_bound(key1)->second == val1);
        REQUIRE(c.lower_bound(nokey) == c.end());
    }

    SECTION("upper_bound") {
        REQUIRE(c.upper_bound("0")->second == val1);
        REQUIRE(c.upper_bound(key1)->second == val2);
        REQUIRE(c.upper_bound(key2) == c.end());
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 2);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("unordered_string_map", "[string_containers]") {
    unordered_string_map<String, string> c;
    c.emplace(key1, val1);
    c.emplace(key2, val2);
    get_allocs();

    SECTION("find") {
        REQUIRE(c.find(key1)->second == val1);
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("at") {
        REQUIRE(c.at(key1) == val1);
        REQUIRE(c.at(key2) == val2);
        REQUIRE_THROWS(c.at(nokey));
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 1);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE((it++)->second == val1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE((it++)->second == val2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 1);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(c.at(key2) == val2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("unordered_string_multimap", "[string_containers]") {
    unordered_string_multimap<String, string> c;
    c.emplace(key1, val1);
    c.emplace(key2, val2);
    c.emplace(key1, val3);
    get_allocs();

    SECTION("find") {
        auto val = c.find(key1)->second;
        REQUIRE((val == val1 || val == val3));
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 2);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        auto v1 = (it++)->second;
        REQUIRE((v1 == val1 || v1 == val3));
        auto v2 = (it++)->second;
        REQUIRE((v2 == val1 || v2 == val3));
        REQUIRE(v2 != v1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE((it++)->second == val2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 2);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(c.find(key2)->second == val2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("string_set", "[string_containers]") {
    string_set<String> c;
    c.emplace(key1);
    c.emplace(key2);
    get_allocs();

    SECTION("find") {
        REQUIRE(*c.find(key1) == key1);
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 1);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE(*it++ == key1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE(*it++ == key2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("lower_bound") {
        REQUIRE(*c.lower_bound("0") == key1);
        REQUIRE(*c.lower_bound(key1) == key1);
        REQUIRE(c.lower_bound(nokey) == c.end());
    }

    SECTION("upper_bound") {
        REQUIRE(*c.upper_bound("0") == key1);
        REQUIRE(*c.upper_bound(key1) == key2);
        REQUIRE(c.upper_bound(key2) == c.end());
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 1);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("string_multiset", "[string_containers]") {
    string_multiset<String> c;
    c.emplace(key1);
    c.emplace(key2);
    c.emplace(key1);
    get_allocs();

    SECTION("find") {
        REQUIRE(*c.find(key1) == key1);
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 2);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE(*it++ == key1);
        REQUIRE(*it++ == key1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE(*it++ == key2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("lower_bound") {
        REQUIRE(*c.lower_bound("0") == key1);
        REQUIRE(*c.lower_bound(key1) == key1);
        REQUIRE(c.lower_bound(nokey) == c.end());
    }

    SECTION("upper_bound") {
        REQUIRE(*c.upper_bound("0") == key1);
        REQUIRE(*c.upper_bound(key1) == key2);
        REQUIRE(c.upper_bound(key2) == c.end());
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 2);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("unordered_string_set", "[string_containers]") {
    unordered_string_set<String> c;
    c.emplace(key1);
    c.emplace(key2);
    get_allocs();

    SECTION("find") {
        REQUIRE(*c.find(key1) == key1);
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 1);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE(*it++ == key1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE(*it++ == key2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 1);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.erase(key1) == 0);
    }
}

TEST_CASE("unordered_string_multiset", "[string_containers]") {
    unordered_string_multiset<String> c;
    c.emplace(key1);
    c.emplace(key2);
    c.emplace(key1);
    get_allocs();

    SECTION("find") {
        REQUIRE(*c.find(key1) == key1);
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.find(nokey) == c.end());
    }

    SECTION("count") {
        REQUIRE(c.count(key1) == 2);
        REQUIRE(c.count(key2) == 1);
        REQUIRE(c.count(nokey) == 0);
    }

    SECTION("equal_range") {
        auto p = c.equal_range(key1);
        auto it = p.first;
        REQUIRE(*it++ == key1);
        REQUIRE(*it++ == key1);
        REQUIRE(it == p.second);

        p = c.equal_range(key2);
        it = p.first;
        REQUIRE(*it++ == key2);
        REQUIRE(it == p.second);

        p = c.equal_range(nokey);
        REQUIRE(p.first == p.second);
    }

    SECTION("erase") {
        REQUIRE(c.erase(nokey) == 0);
        auto stat = get_allocs();
        REQUIRE(stat.is_empty());
        REQUIRE(c.erase(key1) == 2);
        REQUIRE(c.find(key1) == c.end());
        REQUIRE(*c.find(key2) == key2);
        REQUIRE(c.erase(key1) == 0);
    }
}
