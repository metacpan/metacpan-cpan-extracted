#!perl -w

use Test::More 'no_plan';
BEGIN { use_ok('Data::Properties::YAML') };

my $yaml = eval {
  Data::Properties::YAML->new(
    yaml_data => <<'YAML',
---
password_resend:
  general:
    is_not_found: Invalid email address
  contact_email:
    is_missing: Required
    is_invalid: Invalid email address
    is_not_found: Email is not valid - please try again.
YAML
  );
};

ok( $yaml, "Created a new Data::Properties::YAML object" );

ok( $yaml->password_resend, "Has root.password_resend" );
ok( $yaml->password_resend->general, "Has root.password_resend.general" );
ok( $yaml->password_resend->general->is_not_found, "Has root.password_resend.general.is_not_found" );

ok( $yaml->password_resend->contact_email, "Has root.password_resend.contact_email" );
ok( $yaml->password_resend->contact_email->is_missing, "Has root.password_resend.contact_email.is_missing" );
ok( $yaml->password_resend->contact_email->is_invalid, "Has root.password_resend.contact_email.is_invalid" );
ok( $yaml->password_resend->contact_email->is_not_found, "Has root.password_resend.contact_email.is_not_found" );

# Dies when we expect it to die:
eval { $yaml->password_resend->contact_email->isnt_found };
like(
  $@ => qr/Node root\.password_resend\.contact_email has no property named 'isnt_found' at /,
  "Errors correctly"
);

