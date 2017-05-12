package Catmandu::Fix::make_pid;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;
use Catmandu::Fix::Has;

use Catmandu::Store::Resolver;

use Catmandu::Fix::Datahub::Util qw(declare_source);

with 'Catmandu::Fix::Base';

has path     => (fix_arg => 1);
has url      => (fix_arg => 1);
has username => (fix_arg => 1);
has password => (fix_arg => 1);
has type     => (fix_opt => 1, default => sub { return 'work'; });

sub emit {
    my ($self, $fixer) = @_;

    my $perl = '';

    $perl .= 'use Catmandu::Store::Resolver;';

    my $resolver = $fixer->generate_var();
    my $pid = $fixer->generate_var();

    $perl .= "my ${pid};";
    $perl .= declare_source($fixer, $self->path, $pid);

    $perl .= "my ${resolver} = Catmandu::Store::Resolver->new("
    .'url => "'.$self->url.'",'
    .'username => "'.$self->username.'",'
    .'password => "'.$self->password.'",'
    .')->bag;';

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $fixer->split_path($self->path),
        sub {
            my $root = shift;
            my $code = '';
            
            $code .= "my \$t = ${resolver}->get(${pid});";

            # Add _id to $root and set it to the work_pid (persistentURIs[0])
            $code .= 'if (!exists($t->{\'data\'}->{\'persistentURIs\'})) {'
                ."my \$r = ${resolver}->add({"
                    ."id => ${pid},"
                    .'type => "'.$self->type.'"'
                .'});'
                ."${root} = \$r->{'_id'};"
            .'} else {'
                ."${root} = \$t->{'data'}->{'persistentURIs'}->[0];"
            .'}';

            return $code;
        }
    );

    return $perl;
}

1;
__END__

=head1 NAME

Catmandu::Fix::make_pid - Use the L<Resolver|https://github.com/PACKED-vzw/resolver> to create/retrieve a PID for a record

=head1 SYNOPSIS

A fix to either fetch or create a PID (I<workPID>) for
a record based on the record number.

    make_pid(
        path,
        url,
        username,
        password,
        -type: work
    )

=head1 DESCRIPTION

C<make_pid()> will query the resolver to see if a
PID exists for the value in C<path>. If it does, it
replaces the value with the PID. If it doesn't, it
will create the PID and replace the value with the PID.

=head2 PARAMETERS

=head3 Required parameters

C<path>, C<url>, C<username> and C<password> must be present.
Except for C<path>, they are all strings.

=over

=item C<path>

=item C<url>

URL of a Resolver instance (e.g. I<https://resolver.be>).

=item C<username>

=item C<password>

=back

=head3 Optional parameters

=over

=item C<type>

Type of the PID. String, optional and default is 'work'.

=back

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::Resolver>

=head1 AUTHORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 CONTRIBUTORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 COPYRIGHT AND LICENSE

This package is copyright (c) 2016 by PACKED vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
