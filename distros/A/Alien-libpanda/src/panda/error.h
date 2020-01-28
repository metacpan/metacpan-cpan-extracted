#pragma once

#include <system_error>
#include <map>
#include <stack>

#include <panda/memory.h>
#include <panda/string.h>
#include <panda/varint.h>

namespace panda {

namespace error {
    class NestedCategory : public std::error_category {
    public:
        const std::error_category& self;
        const NestedCategory* next;

        constexpr NestedCategory(const std::error_category& self, const NestedCategory* next = nullptr) noexcept : self(self), next(next) {}

        // delegate all implementation to self
        virtual const char* name() const noexcept { return self.name(); }
        virtual std::error_condition default_error_condition(int code) const noexcept { return self.default_error_condition(code); }
        virtual bool equivalent(int code, const std::error_condition& condition) const noexcept {
            return self.equivalent(code, condition);
        }
        virtual bool equivalent(const std::error_code& code, int condition) const noexcept {
            return self.equivalent(code, condition);
        }
        virtual std::string message(int condition) const { return self.message(condition); }
        bool operator==( const std::error_category& rhs ) const noexcept { return self.operator ==(rhs); }
        bool operator!=( const std::error_category& rhs ) const noexcept { return self.operator !=(rhs); }
        bool operator<( const std::error_category& rhs ) const noexcept  { return self.operator <(rhs); }
    };

    const NestedCategory& get_nested_categoty(const std::error_category& self, const NestedCategory* next);
}

struct ErrorCode : AllocatedObject<ErrorCode> {
    ErrorCode() noexcept : ErrorCode(0, std::system_category()) {}
    ErrorCode(const ErrorCode& o) = default;
    ErrorCode(ErrorCode&&) = default;

    ErrorCode(int ec, const std::error_category& ecat) noexcept
        : cat(&error::get_nested_categoty(ecat, nullptr))
    {
        codes.push(ec);
    }

    explicit ErrorCode(const std::error_code& c) noexcept : ErrorCode(c.value(), c.category()) {}

    template< class ErrorCodeEnum >
    explicit ErrorCode(ErrorCodeEnum e) noexcept : ErrorCode(std::error_code(e)) {}

    ErrorCode(const std::error_code& c, const ErrorCode& next) noexcept
        : codes(next.codes)
        , cat(&error::get_nested_categoty(c.category(), next.cat))
    {
        codes.push(c.value());
    }

    ErrorCode& operator=(const ErrorCode& o) noexcept {
        codes = o.codes;
        cat = o.cat;
        return *this;
    }

    ErrorCode& operator=(ErrorCode&& o) noexcept {
        codes = std::move(o.codes);
        cat = o.cat;
        return *this;
    }

    template <class ErrorCodeEnum>
    ErrorCode& operator=(ErrorCodeEnum e) noexcept {
        std::error_code ec(e);
        codes = CodeStack{};
        codes.push(ec.value());
        cat = &error::get_nested_categoty(ec.category(), nullptr);
        return *this;
    }

    void assign( int ec, const std::error_category& ecat ) noexcept {
        codes = CodeStack{};
        codes.push(ec);
        cat = &error::get_nested_categoty(ecat, nullptr);
    }

    void clear() noexcept {
        *this = {};
    }

    int value() const noexcept {
        return codes.top();
    }

    const std::error_category& category() const noexcept {
        return cat->self;
    }

    std::error_condition default_error_condition() const noexcept {
        return code().default_error_condition();
    }

    std::string message() const {
        return cat->message(codes.top());
    }

    string what() const {
        //TODO: optimize with foreach code and next category
        std::string std_msg = message();
        string res(std_msg.data(), std_msg.length());
        if (codes.size() > 1) {
            res += ", preceded by:\n" + next().what();
        }
        return res;
    }

    explicit operator bool() const noexcept {
        return bool(code());
    }

    std::error_code code() const noexcept {
        return std::error_code(codes.top(), cat->self);
    }

    ErrorCode next() const noexcept {
        if (codes.size() <= 1) return {};
        CodeStack new_stack = codes;
        new_stack.pop();
        const error::NestedCategory* new_cat = cat->next;
        return ErrorCode(std::move(new_stack), new_cat);
    }

    ~ErrorCode() = default;

    // any user can add specialization for his own result and get any data
    template <typename T = void, typename... Args>
    T private_access(Args...);

    template <typename T = void, typename... Args>
    T private_access(Args...) const;

private:
    using CodeStack = VarIntStack;

    ErrorCode(CodeStack&& codes, const error::NestedCategory* cat) : codes(std::move(codes)), cat(cat) {}

    CodeStack codes;
    const error::NestedCategory* cat;
};

inline bool operator==(const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return lhs.code() == rhs.code(); }
inline bool operator==(const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() == rhs; }
inline bool operator==(const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs == rhs.code(); }

inline bool operator!=(const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return !(lhs.code() == rhs.code()); }
inline bool operator!=(const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() != rhs; }
inline bool operator!=(const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs != rhs.code(); }

inline bool operator<(const ErrorCode& lhs, const ErrorCode& rhs) noexcept { return lhs.code() < rhs.code(); }
inline bool operator<(const ErrorCode& lhs, const std::error_code& rhs) noexcept { return lhs.code() < rhs; }
inline bool operator<(const std::error_code& lhs, const ErrorCode& rhs) noexcept { return lhs < rhs.code(); }

template< class CharT, class Traits >
std::basic_ostream<CharT,Traits>& operator<<( std::basic_ostream<CharT,Traits>& os, const ErrorCode& ec ) {
    return os << ec.message();
}

}

namespace std {
template<> struct hash<panda::ErrorCode> {
    typedef panda::ErrorCode argument_type;
    typedef std::size_t result_type;

    result_type operator()(argument_type const& c) const noexcept {
        result_type const h1 ( std::hash<std::error_code>{}(c.code()) );
        result_type const h2 ( std::hash<size_t>{}((size_t)&c.category()));
        return h1 ^ (h2 << 1); // simplest hash combine
    }
};
}
