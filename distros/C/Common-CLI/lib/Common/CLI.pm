package Common::CLI;

use warnings;
use strict;

use Carp qw(confess);
use Data::Dumper;
use Data::FormValidator;
use Getopt::Long;
use File::Basename qw(basename);

our $VERSION = '0.04';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->init(@_);
    return $self;
}

sub init {
    my ( $self, %args ) = @_;

    #
    # This allow us to override hard coded arguments in constructor.
    #
    %args = $self->arguments() if !exists $args{profile};

    my ( $profile, $options, $help ) = __parse_profile( $args{profile} );
    $self->options($options);
    $self->profile($profile);
    $self->help($help);
    my $input = __parse_command_line_options($options);
    $self->input($input);
    return;
}

sub profile {
    my $self = shift;
    $self->{profile} = shift if @_;
    return $self->{profile};
}

sub options {
    my $self = shift;
    $self->{options} = shift if @_;
    return $self->{options};
}

sub help {
    my $self = shift;
    $self->{help} = shift if @_;
    return $self->{help};
}

sub input {
    my $self = shift;
    $self->{input} = shift if @_;
    return $self->{input};
}

sub validate_options {
    my $self = shift;

    my $results = Data::FormValidator->check( $self->input(), $self->profile() );

    if ( $results->has_invalid or $results->has_missing ) {
        return ( undef, [ $results->invalid ], [ $results->missing ] );
    }

    #
    # Data::FormValidator::Results->valid returns a hashref in scalar
    # context.
    #

    return scalar $results->valid;
}

sub run {
    my $self = shift;

    my ( $options, $invalid, $missing ) = $self->validate_options();

    #
    # We don't have suitable options to use, show invalid or missing
    # fields before displaying help and exiting.
    #

    if ( $invalid or $missing ) {
        __display_usage();
        __display_invalid($invalid) if $invalid;
        __display_missing($missing) if $missing;
        $self->display_help();
        exit(1);
    }

    if ( $options->{help} ) {
        __display_usage();
        $self->display_help();
        exit(0);
    }

    my $status = $self->main($options);

    return $status;
}

sub main {
    confess "main() must be overriden";
}

sub arguments {
    return ( profile => { optional => [ [ 'help', 'Displays this help' ], ], } );
}

sub merge_arguments {
    my ( $self, $left, $right ) = @_;

    for my $flag (qw( required optional )) {
        for ( @{ $right->{profile}{$flag} } ) {
            push @{ $left->{profile}{$flag} }, $_;
        }
    }

    for my $flag (qw( defaults constraint_methods )) {
        if ( $right->{profile}{$flag}
            and ref $right->{profile}{$flag} eq 'HASH' )
        {

            for ( keys %{ $right->{profile}{$flag} } ) {
                $left->{profile}{$flag}{$_} = $right->{profile}{$flag}{$_}
                  unless exists $left->{profile}{$flag}{$_};
            }
        }
    }

    return %$left;
}

sub display_help {
    my $self = shift;

    for my $item ( @{ $self->help } ) {
        my $message = '';
        $message .= " --" . $item->[0] . "\n";
        $message .= "\t" . $item->[1];

        if ( ${ $self->profile }{defaults}{ $item->[2] } ) {
            $message .= " (default: " . ${ $self->profile }{defaults}{ $item->[2] } . ")";
        }

        $message .= "\n";

        print $message;
    }
}

sub __parse_profile {
    my ($profile) = @_;

    my @options;
    my %profile;
    my @help;

    for my $spec (qw( optional required )) {
        next if !exists $profile->{$spec};
        if ( ref $profile->{$spec} eq 'ARRAY' ) {
            for ( @{ $profile->{$spec} } ) {
                next if ref ne 'ARRAY';

                # store help data
                my @help_data = ( $_->[0], $_->[1] );

                # store `Getopt::Long' description
                unshift @options, $_->[0];

                # remove `Getopt::Long' required data, store only the
                # required bits for `Data::FormValidator'
                ( $_ = $_->[0] ) =~ s/=.*$//;

                # store stripped option
                push @help_data, $_;
                push @help,      \@help_data;

                $profile{$spec} = [] if !exists $profile{$spec};
                unshift @{ $profile{$spec} }, $_;
            }
        }
    }

    for my $spec (qw( constraint_methods require_some defaults )) {
        next if !exists $profile->{$spec};
        next if ref $profile->{$spec} ne 'HASH';
        for my $k ( keys %{ $profile->{$spec} } ) {
            $profile{$spec}{$k} = $profile->{$spec}{$k};
        }
    }

    return ( \%profile, \@options, \@help );
}

sub __parse_command_line_options {
    my ($options) = @_;

    my %parsed_options;
    if ( !GetOptions( \%parsed_options, @{$options} ) ) {
        return;
    }
    return \%parsed_options;
}

sub __display_missing {
    my $missing = shift;

}

sub __display_invalid {
    my $invalid = shift;

}

sub __display_usage {
    my $name = basename($0);
    print "\nUsage: $0 OPTIONS\n\n";
}

1;

__END__

=pod

=head1 NAME

Common::CLI - Command line applications made easy.

=head1 SYNOPSIS

    package My::Application;

    use base 'Common::CLI';

    # This sub will be used by init() if no argument is given to new()
    sub arguments {
        return (
            profile => {
                'optional' => [ [ 'output-format=s', 'Output format' ], ],

                'defaults' => { 'output-format' => 'html', },
            }
        );
    }

    # This is your main subroutine, which will be called by run() after options
    # parsing and validation
    sub main {
        my ( $self, $options ) = @_;

        my $output_format = $options->{'output-format'};

        # ...

        # This will be used by run() to exit
        return $status;
    }

    package main;

    # Instantiate and run your brand new application
    exit My::Application->new()->run();

=head1 ABSTRACT

L<Common::CLI> is a glue between L<Getopt::Long> and
L<Data::FormValidator>, aimed to be a handy tool to construct command
line interface programs.

The L<Data::FormValidator> profile was slightly modified, to handle
L<Getopt::Long> parameters and help information.

After successful parsing, the result is validated against
L<Data::FormValidator>, which is responsible for validation
constraints and applying default values.

Then, it surprisingly delegates control to C<main()> subroutine, which
will contain your business logic.

L<Common::CLI> will handle by default the C<--help> option, which will
display usage information, based on the C<profile> given, and exit. If
there's some non-existant, missing or invalid option, it will inform
you what went wrong, and also display the usage.

=head1 API

=over 4

=item new(%profile)

If C<%profile> is C<undef>, will use package's defined C<arguments()>
otherwise will use C<%profile> to build options used by
L<Getopt::Long>, profile used by L<Data::FormValidator> and help
information.

    package My::Application;

    # ...

    My::Application->new(
        profile => {
            'optional' => [
                [ 'notify=s@', 'Notify given email after execution' ]
            ],
        }
    );
            

=item init(%args)

This method is used to initialize the object. Really. Basically it
generates L<Data::FormValidator> compatible profile, L<Getopt::Long>
compatible options and help information. If you're planning to
override this, don't forget to call C<SUPER::init(%args)>!

=item profile($profile)

Setter and getter for L<Data::FormValidator> compatible profile.

=item options($options)

Setter and getter for L<Getopt::Long> compatible options.

=item help($help)

Setter and getter for generated help information.

=item input($input)

Setter and getter for user input data (usually L<Getopt::Long> parsed
options).

=item validate_options()

Validated parsed input from command line against informed profile
using L<Data::FormValidator>. Returns a list with the parsed options
after validation and invalid and missing options if any:

    my ( $options, $invalid, $missing ) = $self->validate_options();

=item run()

C<run()> is responsible basically for obtain validated options using
C<validate_options()>, and display the help message if anything went
wrong or if user required to do so. If any of this happened, it will
execute C<main()> and exit using its exit code.

=item main($options)

This routine must be overriden by all C<Common::CLI> subclasses. It
will be filled by the developer with any business logic he or she
wants.

=item arguments()

This routine can be overriden L<Common::CLI> subclasses, and must
return a hash containing at least a C<profile> key, with
C<Common::CLI> profile data. It will be used if the C<profile> key is
not provided in C<new()>:

    package My::Application;

    sub arguments {
        return (
            profile => {
                'optional' =>
                  [ [ 'email', 'Your email address', ] ],
            },
        );
    }

    # ...

    package main;

    My::Application->new()->run();

By default, it returns an empty list.

=item merge_arguments()

This routine is used to merge your application defined arguments with
SUPER defined arguments:
    
    package My::App;

    use base 'Common::CLI';

    sub arguments {
        my $self = shift;
        return $self->merge_arguments(
            { $self->SUPER::arguments },
            {
                profile => {
                    required =>
                      [ [ 'import=s', 'Import this file' ], ]
                }
            }
        );
    }

    # ...

    package My::Other::App;

    use base 'My::App';

    sub arguments {
        my $self = shift;
        return $self->merge_arguments(
            { $self->SUPER::arguments },
            {
                profile =>
                  { optional => [ [ 'format=s', 'Input format' ], ] }
            }
        );
    }

Our profile will be:

    {
        profile => {
            required => [ [ 'import=s', 'Import this file' ], ],
            optional => [ [ 'format=s', 'Input format' ], ],
        },
    }

=item display_help()

Print the help usage to STDOUT. This won't print missing or invalid
options information. An example:

    Usage: sample.pl OPTIONS

      --help
            Show help
      --notify=s@
            Notify given email after execution           

=item __parse_profile()

Parse user given profile. Return a list with L<Data::FormValidator>
compatible profile hashref, a L<Getopt::Long> compatible options
arrayref and help information arrayref:

    my ( $profile, $options, $help ) = __parse_profile($given_profile);

=item __parse_command_line_options( $options )

Returns a hashref with L<Getopt::Long> parsed options, or C<undef> if
something went wrong:

    my $input = __parse_command_line_options($options);

=item __display_missing( $missing )

Being C<$missing> an arrayref of missing elements from obtained from
C<validate_options()>, print them to STDOUT.

=item __display_invalid( $invalid )

Being C<$invalid> an arrayref of missing elements from obtained from
C<validate_options()>, print them to STDOUT.

=item __display_usage()

Display the usage header.

=back

=head1 AUTHOR

Copyright (c) 2008, Igor Sutton Lopes "<IZUT@cpan.org>". All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Getopt::Long>, L<Data::FormValidator>

=cut
