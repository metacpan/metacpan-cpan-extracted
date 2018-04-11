#pragma once

#if __cpp_lib_optional >= 201603L
#  include <optional>
namespace panda {
  template <typename T>
  using optional = std::optional<T>;
}
#else

namespace panda {
  template <typename T>
  struct optional {
    optional() : exists(false) {}
    optional(const T& val) :val(val), exists(true) {}

    T value() const {
      return val;
    }

    T value_or(const T& def) const {
      return exists ? val : def;
    }

    explicit operator bool() const {
      return exists;
    }

    T val;
    bool exists;
  };

  template <typename T>
  struct optional_tools {
      using type = optional<T>;
      static type default_value() {return type{};}
  };

  template <>
  struct optional_tools<void> {
      static void default_value(){}
      using type = void;
  };
}

#endif

