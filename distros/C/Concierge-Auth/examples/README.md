# Concierge::Auth Examples

## 1-custom-backend-ldap.pl

A sketch of a directory-backed (LDAP) `Concierge::Auth::Base` implementation.
It shows how little code is needed to satisfy the five-method backend
contract (`new`, `authenticate`, `is_id_known`, `enroll`,
`change_credentials`, `revoke`) once you have the connection details for a
real directory server (host, bind DN, bind password, base DN).

This is a documentation sketch, not a shipped backend: it requires
`Net::LDAP` (not a dependency of this distribution) and a real directory
server to run against.

```bash
perl 1-custom-backend-ldap.pl
```

## More examples planned

Additional examples covering the built-in `Concierge::Auth::Pwd` backend
(the one used in the top-level README's Quick Start) and the generator
methods are planned for a future release.

## See Also

- [Concierge::Auth::Base](../lib/Concierge/Auth/Base.pm) - the five-method backend contract
- [Concierge::Auth::Pwd](../lib/Concierge/Auth/Pwd.pm) - the built-in reference implementation
