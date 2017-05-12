
package Data::Template;

=encoding utf8
=cut

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);
Data::Template->mk_accessors(qw(engine prefix));

use Template;

sub new {
    my $self = shift;
    my $TT = Template->new(INTERPOLATE => 1);
#    return $self->SUPER::new({engine => $TT, prefix => '=', @_});
    return $self->SUPER::new({engine => $TT, @_});
}

sub process {
    my $self = shift;
    my $tt = shift;
    my $vars = shift;

    if (!ref $tt) {
        return $self->process_s($tt, $vars);
    } elsif (ref $tt eq 'ARRAY') {
        return $self->process_a($tt, $vars);
    } elsif (ref $tt eq 'HASH') {
        return $self->process_h($tt, $vars);
    } else {
        die 'burp'
    }
}

sub process_h {
    my $self = shift;
    my $h = shift;
    my $vars = shift;

    my %ph = ();
    while (my ($k, $v) = each %$h) {
        $k = $self->process_s($k, $vars);
        $v = $self->process($v, $vars);
        $ph{$k} = $v;
    }
    return \%ph;
}

sub process_a {
    my $self = shift;
    my $a = shift;
    my $vars = shift;

    my @pa;
    foreach (@$a) {
        push @pa, $self->process($_, $vars);
    }
    return \@pa;
}

=begin private

    ($p, $t) = $self->_split_scalar($s)

Determines if C<$s> is a plain scalar or
a text template. If it is a plain scalar,
C<$p> gets its content and C<$t> gets C<undef>.
Otherwise, C<$p> is C<undef> and C<$t>
gets the contents of the template.

There is difference between C<$s> and
the content of C<$s> only if there is a
C<prefix>. In this case, a plain scalar
is (1) one which does not begin with the prefix
(the content is C<$s> itself) or (2)
one which begins with C<"\\"> followed
by the prefix (the content is C<$s> without
the leading escape). When there is
a prefix, C<$s> is a template if it begins
with the prefix and its content is C<$s>
without the prefix.

    # say prefix is '='
    ($p, $t) = $tt->_split_scalar('foo') 
    # ($p, $t) = ('foo', undef)
    ($p, $t) = $tt->_split_scalar('=foo')
    # ($p, $t) = (undef, 'foo')
    ($p, $t) = $tt->_split_scalar('\\=foo')
    # ($p, $t) = ('=foo', undef)

=end private

=cut

sub _split_scalar {
    my $self = shift;
    my $s = shift;
    my $prefix = $self->prefix;
    if ($prefix) {
        if ($s =~ s/^\Q$prefix\E//) { # it is a template
            return (undef, $s);
        } else {
            $s =~ s/^\\(\Q$prefix\E)/$1/; # chomp the leading escape
            return ($s, undef);
        }
    }
    # by now everything else looks like a template
    return (undef, $s);
}

sub process_s {
    my $self = shift;
    my $s = shift;
    my $vars = shift;

    my ($p, $t) = $self->_split_scalar($s);
    return $p if defined $p;

    my $ps;
    $self->engine->process(\$t, $vars, \$ps)
        or die $self->engine->error();
    return $ps;
 

}

1;

__END__

=head1 NAME

Data::Template - Generate data structures from templates

=head1 SYNOPSIS

    use Data::Template;

    $dt = Data::Template->new();
    $tt = {
        who => 'me',
        to => '${a}',
        subject => 'Important - trust me',
        body => <<'BODY',
    
            When I was ${b}, I realized that
            I had not ${c}. Do you?
    BODY
    };
    $data = $dt->process($tt, { a => 'someone', b => 'somewhere', c => '100$' });

=head1 DESCRIPTION

Templates usually convert text templates to text. This
module goes further by converting data structure 
templates to data structures.

Beyond that, nothing new. I am lazy and the Template Toolkit is
here today - so I use it.

The current implementation handles hash refs, array refs
and non-ref scalars (strings). The I<processing rules> are:

=over 4

=item *

(outdated)
Each non-ref scalar starting with '=' is processed as a template.

=item *

(outdated)
Other non-ref scalars are left as they are. Except, those starting 
with '\=' for which C<s/^\\=/=/> is done (a way to have strings
starting with '=').

=item *

Array refs have their elements recursively I<processed>.

=item *

Hash refs have keys processed as non-ref scalars and values
recursively I<processed>.

=back

(The implementation so far is so naïve that causes laughs.
But laughing may be good.)

=head2 FUNCTIONS

=over 4

=item B<new>

A constructor. Wow!

=item B<process>

    $data = $dt->process($tt, $vars)

Process the templates generating a new data structure.
It dies on errors (or not - see constructor parameters
to come soon).

=item B<process_s>

For processing a scalar.

=item B<process_a>

For processing an array.

=item B<process_h>

For processing a hash.

=back

=head1 EXAMPLES

Soon.

=head1 SEE ALSO

L<Template> - as this is used to process the text templates.

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Template

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


