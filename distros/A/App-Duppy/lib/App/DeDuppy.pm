package App::DeDuppy;

# ABSTRACT: generate json files from casperjs test arguments
use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
use MooX::Options;
use JSON;

option 'arglist' => (is => 'ro',
                     format => 's',
                     required => 1,
                     doc => 'the original casperjs arguments');

option 'output' => (is => 'ro',
                    format => 's',
                    predicate => 'is_output_set');

has 'options' => (is => 'ro',
                  default => sub { {} });

has 'subcommand' => (is => 'ro',
                     writer => 'set_subcommand',
                     predicate => 'subcommand_is_set');

has 'paths' => (is => 'ro',
                default => sub { [] });

sub truthify_maybe {

    $_[0] eq 'false' ? JSON::false :
    $_[0] eq 'true'  ? JSON::true  : $_[0];

}

sub arrayrefify_maybe {

    my @values = split(/,/, $_[0]);
    if (@values > 1) {
        return [ map { truthify_maybe($_) } @values ];
    }
    return truthify_maybe($values[0]);

}

sub repsac_nur {

    # if you play it backwards it sounds like an Elvis record

    my $self = shift;

    foreach my $argument (split(/\s+/, $self->arglist)) {

        # four types of args: --option, --option=value (there's always
        # a = in there fortunately), subcommand (the first arg that's
        # not an option), and test files

        if ($argument =~ m/^--(?<option>[^=]+)(?:=(?<value>.+))?/) {

            my ($option, $value) = ($+{option}, $+{value});
            $self->options->{$option} = defined $value ? arrayrefify_maybe($value) : JSON::true;

        } else {

            if ($self->subcommand_is_set) {

                push @{$self->paths}, $argument;

            } else {

                $self->set_subcommand($argument);

            }

        }

    }

    my $json = JSON->new->pretty->encode({ %{$self->options}, paths => $self->paths });
    if ($self->is_output_set) {
        open my $fh, '>', $self->output
            or croak sprintf(q{Cannot open '%s' for writing: %s},
                             $self->output, $!);
        $fh->print($json);
        $fh->close;
    } else {
        print $json;
    }

}


1;

__END__
=pod

=head1 NAME

App::DeDuppy - generate json files from casperjs test arguments

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  # will build json files used by duppy
  deduppy --option1=value1 --option2=value2 --output=toafile.json

=head1 DESCRIPTION 

This is the companion script to L<duppy>, which role is to ease the process of building up json files used by duppy.

It makes no assumption about the validity of the options you are passing, so you should better be careful. 

=head1 AUTHORS

=over 4

=item *

Emmanuel "BHS_error" Peroumalnaik

=item *

Fabrice "pokki" Gabolde

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by E. Peroumalnaik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

