package App::CLI::Toolkit;

use warnings;
use strict;

use Carp;
use File::Basename;
use Getopt::Long;

our $VERSION = '0.03';
our $AUTOLOAD;

sub new {
    my $class  = shift;
    my %config = @_;

    my $self = \%config;
    bless $self, $class;

    $self->{_opts} = {};

    if (exists $self->{description} && ref($self->{description})) {
        croak "description should be a plain string";
    }

    if (exists $self->{options}) {
        if (!UNIVERSAL::isa($self->{options}, 'HASH')) {
            croak "params argument should be a hash ref";
        }
        
        if (!(grep { /\bh(elp)?\b/ } keys %{$self->{options}}) && !$self->{noautohelp}) {
            $self->{options}{'help|h'} = "Show this help documentation";
        }
        GetOptions($self->{_opts}, keys %{$self->{options}}) or $self->_exit_with_usage(1);
    }

    if (exists $self->{params}) {
        if (!UNIVERSAL::isa($self->{params}, 'ARRAY')) {
            croak "params argument should be an array ref";
        }
        my @params = @{$self->{params}};
        
        my $found_multi_value_param = 0;
        my $found_optional_param = 0;
        
        foreach my $param (@params) {
            if ($param !~ /^\w+[\*\+\?]?$/) {
                croak "Invalid param name $param: must match \\w+ with optional trailing [*+?]";
            } 
            
            if ($param =~ /[\*\+]$/) {
                if ($found_optional_param) {
                    croak "Can't have multiple-value parameter after an optional parameter";
                }
                if ($found_multi_value_param) {
                    croak "Can't have more than one multiple-value parameter"
                }
                $found_multi_value_param = 1;
                $found_optional_param = 1 if $param =~ /\*$/;
            } elsif ($param =~ /\?$/) {
                if ($found_multi_value_param) {
                    croak "Can't have optional parameter after a multiple-value parameter";
                }
                $found_optional_param = 1;
            }
            
            if ($param !~ /[\?\*]/ && $found_optional_param) {
                croak "Can't have a non-optional parameter after an optional parameter";
            }
        }

        # Check number of elements in ARGV is at least as many as the number of
        # non-optional params
        if ((grep { /[\w\+]$/ } @params) > @ARGV) {
            $self->_exit_with_usage(1, "Missing command-line parameters");
        }

        my $shifting = 1;
        while (@params && @ARGV) {
            my ($key, $value);
            if (@params > 1 && $params[0] =~ /[\+\*]$/ && $shifting) {
                # we've found the multi-value params, so start popping from
                # the end of @params instead of shifting from the front
                $shifting = 0;
            }
            
            $key = $shifting ? shift @params : pop @params;
            if ($key =~ /[\+\*]$/) {
                $key   =~ s/[\+\*]$//;
                $value = [ @ARGV ];
                @ARGV  = ();
            } else {
                $value = $shifting ? shift @ARGV   : pop @ARGV;
                $key   =~ s/\?$//;
            }
            if (exists $self->{_opts}{$key}) {
                croak "Can't have a param and an option with the same name ($key)";
            }
            $self->{_opts}{$key} = $value;
        }
    }
    
    if (exists $self->{_opts}{help} && $self->{_opts}{help}) {
        $self->_exit_with_usage(0);
    }

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $key  = $AUTOLOAD;
    $key =~ s/.*:://; # trim off package qualifier

    # If the key contains an underscore it might represent a key with
    # a hyphen - let's check
    if ($key =~ /_/) {
        (my $alt_key = $key) =~ s/_/-/g;
        if (!exists $self->{_opts}{$key} && exists $self->{_opts}{$alt_key}) {
            $key = $alt_key;
        }
    }

    return $self->get($key);
}

sub get {
    my $self = shift;
    my $key  = shift;
    my $retval = $self->{_opts}{$key};
    if (UNIVERSAL::isa($retval, 'ARRAY') && wantarray) {
        return @$retval;
    } else {
        return $retval;
    }
}

# Explicit DESTROY, else it gets handled by AUTOLOAD
sub DESTROY {}

sub usage {
    my $self        = shift;
    my $result      = '';
    my $script_name = basename($0);
    my $description = $self->{description};

    my %ARG_TYPES = ( 
        s => 'STR',
        i => 'INT',
        f => 'FLOAT',
    );
    
    $result .= "Usage: $script_name";
    $result .= " [OPTIONS]" if $self->{options};
    foreach my $param (@{$self->{params}}) {
        if ($param =~ /^(.*)\+$/) {
            my $p = uc $1;
            $result .= " $p [$p...]";
        } elsif ($param =~ /^(.*)\*$/) {
            my $p = uc $1;
            $result .= " [$p $p...]";
        } elsif ($param =~ /^(.*)\?$/) {
            my $p = uc $1;
            $result .= " [$p]";
        } else {
            $result .= " " . uc($param);
        }
    }
    $result .= "\n";
    $result .= $self->{description} . "\n" if $self->{description};

    if ($self->{options}) {
        $result .= "\nArguments shown for an option apply to all variants of that option\n";
        foreach my $opt (sort keys %{$self->{options}}) {
            my ($arg_type, @variants);
            my $option = '';
    
            if ($opt =~ /^(.*)=([sif])([\%\@])?$/) {
                @variants = split(/\|/, $1);
                $arg_type = $ARG_TYPES{$2};
                $option   = $3 || '';
            } elsif ($opt =~ /^(.*)([\+])$/) {
                @variants = split(/\|/, $1);
                $option   = $2;
            } else {
                @variants = split(/\|/, $opt);
            }
            my $variants_str = join(
                ", ", 
                map { length > 1 ? "--$_" : "-$_" } 
                sort { length($a) <=> length($b) }
                @variants
            );
            if ($arg_type && $option eq '%') {
                $variants_str .= " KEY=$arg_type";
            } elsif ($arg_type) {
                $variants_str .= " $arg_type";
            }
            $result .= " " x 2 . $variants_str . "\n";
            $result .= " " x 4 . $self->{options}{$opt} . "\n";
            $result .= " " x 4 . "(Use more than once for enhanced effect)" . "\n" if $option eq '+';
            $result .= " " x 4 . "(Use more than once to specify multiple values)" . "\n" if $option eq '@' || $option eq '%';
        }
    }
    return $result;
}

sub _exit_with_usage {
    my $self      = shift;
    my $exit_code = shift || 0;
    my $msg       = shift;
    
    print "$msg\n" if $msg;
    print $self->usage;
    exit($exit_code);
}

1;

=head1 NAME

App::CLI::Toolkit - a helper module for generating command-line utilities

=head1 DESCRIPTION

App::CLI::Toolkit is designed to take the hassle out of writing command-line apps
in Perl. It handles the parsing of both parameters and options (see below for
the distinction) and generates usage information from the details you give it.

=head1 SYNOPSIS

    use App::CLI::Toolkit;

    my $app = App::CLI::Toolkit->new(
        description = 'A replacement for cp',
        params      = [ qw(source dest) ],
        options     = { 
            'recursive|r' => 'If source is a directory, copies'
                           . 'the directory contents recursively',
            'force|f'     => 'If target already exists, overwrite it'
            'verbose|v'   => 'Produce verbose output'
        }
    );
    
    print "Copying " . $app->source . " to " . $app->dest . "\n" if $app->verbose;
    
    if ($app->recursive) {
        # Do recursive gumbo
    }
    
    if ($app->force) {
        # Don't take no for an answer
    }
    ...

=head1 CONSTRUCTOR

 App::CLI::Toolkit->new(%config)

Constructs a new App::CLI::Toolkit object

=head2 Constructor arguments

=head3 description

A description of what the app does. Used in the usage string that 
App::CLI::Toolkit generates.

Example:

 $app = new App::CLI::Toolkit(description => 'A cool new replacement for grep!')

=head3 noautohelp

App::CLI::Toolkit automatically gives your app help options (-h and --help). 
Supply a noautohelp value that equates to true (e.g. 1) to suppress this.

=head3 options

A reference to a hash mapping option names to a description of what the option
does. The hash keys follow the conventions of L<Getopt::Long>.

=head3 params

A reference to an array of parameter names. When the app is invoked, parameters
follow the app name on the command line.

Example:

 $app = new App::CLI::Toolkit(params => ['name'])
 print uc $app->name

Yields this result:

 $ my-app fred
 FRED

=over

=item Optional parameters

Parameters can be optional, in which case your application will provide a default
if the user doesn't provide a parameter. For example, the target argument to C<ln>
is optional and defaults to the filename of the source in the current working directory.

Specify an optional argument in C<App::CLI::Toolkit> by adding C<?> to the end of the
parameter name.

Example:

 $app = new App::CLI::Toolkit(params => ['target?']);
 print $app->target || $ENV{PWD} . "\n"

Yields this result:

 $ my-app /var/tmp
 /var/tmp
 
 $ my-app
 /home/simon

=item Multiple-Value Parameters

Applications can take one or more instances of a particular parameter. For example,
C<mv> takes one or more file arguments followed by a single target parameter.

Specify a multiple-value argument in C<App::CLI::Toolkit> by adding C<+> to the end of the
parameter name.

The accessor for multiple-value parameters returns a list, even if the user only supplied 
one value.

Example:

 $app = new App::CLI::Toolkit(params => ['files+']);
 print join(', ', $app->files) . "\n"

Yields this result:

 $ my-app foo bar wibble
 foo, bar, wibble

=item Optional, Multiple-Value Parameters

Applications can take zero or more instances of a particular parameter. For example,
C<ls> takes either no parameters (in which case it lists the contents of the current
working directory) or a list of parameters (in which case it lists the contents of
each parameter).

Specify an optional, multiple-value argument in C<App::CLI::Toolkit> by adding C<*> 
to the end of the parameter name.

The accessor for optional, multiple-value parameters returns a list, even if the 
user only supplied one value.

Example:

 $app = new App::CLI::Toolkit(params => ['dirs*']);
 if ($app->dirs) {
   print join(', ', $app->dirs) . "\n";
 } else {
   print "No dirs given, using $ENV{PWD}\n";
 }

Yields this result:

 $ my-app foo bar wibble
 foo, bar, wibble
 
 $ my-app foo
 foo
 
 $ my-app
 No dirs given, using /home/simon

=item Some notes about optional and multiple-value parameters

=over

=item *

You can only have one multiple-value parameter type per application.

=item *

You can't follow an optional parameter type with a non-optional parameter type.

=back

=back

=head1 METHODS

=head2 App-specific accessors

Your App::CLI::Toolkit object has methods named after each of the params and
options specified in the constructor.

Example:

 $app = App::CLI::Toolkit(
    params => [ qw(foo bar?) ],
    options => {
        'verbose|v' => 'Give more verbose output',
    }
 )
 print $app->foo;
 print $app->bar if $app->bar;
 
 print "Some verbose rubbish\n" if $app->verbose;
 
Where an option has multiple labels (eg. C<verbose> and C<v> in the above example),
the accessor has the name of the first label in the list.

=head2 get(key)

Gets the value stored against key, where key is an option name or param label. 
This is an alternative to the convenience accessors named after the option name
or param label.

Example:

 $app = App::CLI::Toolkit(params => ['foo'])
 
 print $app->foo;       # prints the value of the 'foo' param
 print $app->get('foo') # same

=head2 usage()

Gets the usage string for your application

=head1 AUTHOR

Simon Whitaker, C<< <swhitaker at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-cli-toolkit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-CLI-Toolkit>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::CLI::Toolkit

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-CLI-Toolkit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-CLI-Toolkit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-CLI-Toolkit>

=item * Search CPAN

L<http://search.cpan.org/dist/App-CLI-Toolkit>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Chris Lokotsch for the code reviews.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Simon Whitaker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


