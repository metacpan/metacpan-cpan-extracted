package CSAF::Util::Options;

use 5.010001;
use strict;
use warnings;
use utf8;

use YAML::XS 'LoadFile';

use Moo::Role;

$YAML::XS::LoadBlessed = 0;

has config_file =>
    (is => 'rw', isa => sub { Carp::croak "Unable to open configuration file" unless -e $_[0] }, trigger => 1);

sub _trigger_config_file {

    my $self = shift;

    my $config_data = LoadFile($self->config_file);

    foreach my $config_name (keys %{$config_data}) {

        my $config_value = $config_data->{$config_name};

        $config_name =~ s/\-/_/;
        $self->$config_name($config_value) if $self->can($config_name);

    }

}

sub configure {

    my ($self, %args) = @_;

    foreach my $method (keys %args) {
        my $value = $args{$method};
        $self->$method($value) if $self->can($method);
    }

}

sub clone {

    my $self  = shift;
    my $clone = {%$self};

    bless $clone, ref $self;
    return $clone;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Util::Options - Options utility for CSAF

=head1 SYNOPSIS

    package My::CSAF::Options {

        use Moo;
        with 'CSAF::Util::Options';

        has enable_foo => (is => 'rw', required => 1);
        has make_bar => (is => 'rw');

    }

    package My::CSAF {

        use Moo;
        use My::CSAF::Options;

        has options => (is => 'lazy', build => 1);

        sub _build_options { My::CSAF::Options->new }

        sub my_job {

            my $self = shift;

            $self->options->configure(make_bar => $bar);

            if ($self->options->enable_foo) {
                [...]
            }
        }

    }


=head1 DESCRIPTION

L<CSAF::Util::Options> is L<Moo> role and utility for L<CSAF>.

=head2 ATTRIBUTES

=over

=item config_file

Load config from YAML file.

=back

=head2 METHODS

=over

=item configure

Configure an item.

    $options->configure(
        foo => 'foo',
        bar => 'bar',
        baz => 'baz'
    );

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
