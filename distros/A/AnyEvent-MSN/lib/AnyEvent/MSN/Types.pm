package AnyEvent::MSN::Types;
{ $AnyEvent::MSN::Types::VERSION = 0.002 }
use Moose::Util::TypeConstraints;

#
subtype 'AnyEvent::MSN::Types::Passport', as 'Str' => where {
    my $atom       = qr{[a-zA-Z0-9_!#\$\%&'*+/=?\^`{}~|\-]+};
    my $dot_atom   = qr{$atom(?:\.$atom)*};
    my $quoted     = qr{"(?:\\[^\r\n]|[^\\"])*"};
    my $local      = qr{(?:$dot_atom|$quoted)};
    my $quotedpair = qr{\\[\x00-\x09\x0B-\x0c\x0e-\x7e]};
    my $domain_lit = qr{\[(?:$quotedpair|[\x21-\x5a\x5e-\x7e])*\]};
    my $domain     = qr{(?:$dot_atom|$domain_lit)};
    my $addr_spec  = qr{$local\@$domain};
    $_ =~ $addr_spec;
} => message {
    'An MSN Passport looks like an email address: you@hotmail.com';
};

#
subtype 'AnyEvent::MSN::Types::OnlineStatus' =>
    as enum([qw[NLN FLN BSY IDL BRB AWY PHN LUN]]);

#
no Moose::Util::TypeConstraints;
1;
