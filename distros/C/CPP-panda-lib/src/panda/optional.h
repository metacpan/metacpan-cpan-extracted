#pragma once

#if __cpp_lib_optional >= 201603L
#  include <optional>
namespace panda {
  template <typename T>
  using optional = std::optional<T>;
}
#else

namespace panda {

// see catch_option.hpp from Catch2 
template <typename T> struct optional {
    ~optional() { reset(); }

    optional() : nullable_val(nullptr) {}
    
    optional(const T& val) : nullable_val(new (storage) T(val)) {}
    
    optional(const optional& oth) : nullable_val(oth ? new (storage) T(*oth) : nullptr) {}
    
    optional& operator=(optional const& oth) {
        if (&oth != this) {
            reset();
            if (oth)
                nullable_val = new (storage) T(*oth);
        }
        return *this;
    }
    
    optional& operator=(const T& val) {
        reset();
        nullable_val = new (storage) T(val);
        return *this;
    }

    void reset() {
        if (nullable_val)
            nullable_val->~T();
        nullable_val = nullptr;
    }

    T&       operator*() { return *nullable_val; }
    const T& operator*() const { return *nullable_val; }
    T*       operator->() { return nullable_val; }
    const T* operator->() const { return nullable_val; }

    T value_or(const T& default_val) const { return nullable_val ? *nullable_val : default_val; }

    T value() const { return *nullable_val; }

    explicit operator bool() const { return nullable_val != nullptr; }

private:
    T* nullable_val;
    alignas(alignof(T)) char storage[sizeof(T)];
};

template <typename T> struct optional_tools {
    using type = optional<T>;
    static type default_value() { return type{}; }
  };

  template <>
  struct optional_tools<void> {
      static void default_value(){}
      using type = void;
  };
}

#endif
