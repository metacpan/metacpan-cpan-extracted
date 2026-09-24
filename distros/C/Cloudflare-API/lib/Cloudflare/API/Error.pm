#
#  This file is part of Cloudflare::API.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Cloudflare::API::Error;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;


#  External modules
#
use overload '""' => 'as_string', fallback => 1;


#  Version information
#
$VERSION='1.010';


#  All done. Positive return
#
1;


#============================================================================


sub new {

    my ($class, %opt)=@_;
    my $self=bless(\%opt, $class);
    return $self;

}


sub response { return $_[0]->{'response'} }
sub errors   { return $_[0]->{'errors'} || [] }
sub messages { return $_[0]->{'messages'} || [] }


sub as_string {


    #  Render Cloudflare's error messages for ordinary exception output
    #
    my ($self)=@_;
    my $errors_ar=$self->errors();
    my @message=map { ref($_) eq 'HASH' ? ($_->{'message'} || '') : '' } @$errors_ar;
    @message=grep { length($_) } @message;
    return @message ? join('; ', @message) : 'Cloudflare API reported failure';

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Error #

# NAME #

Cloudflare::API::Error - exception for a failed Cloudflare JSON response

# SYNOPSIS #

```perl
my $result=eval { $api->zones()->get($zone_id) };
if (my $error=$@) {
    if (ref($error) && $error->isa('Cloudflare::API::Error')) {
        warn $error->as_string();
        my $details=$error->errors();
    }
}
```

# DESCRIPTION #

`Cloudflare::API` throws this exception when the HTTP request succeeds but the decoded JSON envelope contains `success: false`. HTTP and transport failures instead throw `HTTP::API::Core::Error`. The error object retains the original response and Cloudflare's error and message arrays.

# METHODS #

* **new(%fields)** — Construct an exception object from `response`, `errors`, and `messages`. This is normally called by `Cloudflare::API`; it returns a `Cloudflare::API::Error` object.
* **response()** — Return the original `HTTP::API::Core::Response` object, or `undef` if one was not supplied.
* **errors()** — Return Cloudflare's `errors` value, or an empty array reference if absent or false.
* **messages()** — Return Cloudflare's `messages` value, or an empty array reference if absent or false.
* **as_string()** — Join non-empty `message` fields from hash entries in `errors` with semicolons. If none are present, return `Cloudflare API reported failure`. Stringification invokes this method automatically.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), HTTP::API::Core::Error

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Cloudflare::API.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Cloudflare::API::Error - exception for a failed Cloudflare JSON response


=head1 SYNOPSIS


 my $result=eval { $api->zones()->get($zone_id) };
 if (my $error=$@) {
     if (ref($error) && $error->isa('Cloudflare::API::Error')) {
         warn $error->as_string();
         my $details=$error->errors();
     }
 }

=head1 DESCRIPTION

C<Cloudflare::API> throws this exception when the HTTP request succeeds but the decoded JSON envelope contains C<success: false>. HTTP and transport failures instead throw C<HTTP::API::Core::Error>. The error object retains the original response and Cloudflare's error and message arrays.


=head1 METHODS

=over

=item *

B<new(%fields)> — Construct an exception object from C<response>, C<errors>, and C<messages>. This is normally called by C<Cloudflare::API>; it returns a C<Cloudflare::API::Error> object.


=item *

B<response()> — Return the original C<HTTP::API::Core::Response> object, or C<undef> if one was not supplied.


=item *

B<errors()> — Return Cloudflare's C<errors> value, or an empty array reference if absent or false.


=item *

B<messages()> — Return Cloudflare's C<messages> value, or an empty array reference if absent or false.


=item *

B<as_string()> — Join non-empty C<message> fields from hash entries in C<errors> with semicolons. If none are present, return C<Cloudflare API reported failure>. Stringification invokes this method automatically.


=back


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>, HTTP::API::Core::Error


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
