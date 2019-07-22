package Astro::App::Satpass2::Format::Template;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::Format };

use Astro::App::Satpass2::Locale qw{ __localize };
# use Astro::App::Satpass2::FormatValue;
use Astro::App::Satpass2::FormatValue::Formatter;
use Astro::App::Satpass2::Utils qw{
    instance
    ARRAY_REF
    HASH_REF
    SCALAR_REF
    @CARP_NOT
};
use Astro::App::Satpass2::Wrap::Array;
use Astro::Coord::ECI::TLE 0.059 qw{ :constants };
use Astro::Coord::ECI::Utils 0.059 qw{
    deg2rad embodies julianday PI rad2deg TWOPI
};
use Clone qw{ };
use POSIX qw{ floor };
use Template;
use Template::Provider;
use Text::Abbrev;
use Text::Wrap qw{ wrap };

our $VERSION = '0.040';

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new( @args );

    # As of 0.020_002 the template definitions are in the
    # locale system. The attribute simply holds modifications.
    $self->{canned_template} = {};

    $self->_new_tt( $self->permissive() );

    $self->{default} = {};
    $self->{formatter_method} = {};

    return $self;
}

sub _new_tt {
    my ( $self, $permissive ) = @_;

    $self->{tt} = Template->new(
	{
	    LOAD_TEMPLATES => [
		Template::Provider->new(
		    ABSOLUTE	=> $permissive,
		    RELATIVE	=> $permissive,
		),
	    ],
	}
    ) or $self->weep(
	"Failed to instantate tt: $Template::ERROR" );

    return;
}

sub add_formatter_method {
    # TODO I want the arguments to be ( $self, $fmtr ), but for the
    # moment I have to live with an unreleased version that passed the
    # name as the first argument. I will go to the desired signature as
    # soon as I get this version installed on my own machine.
    my ( $self, @arg ) = @_;
    my $fmtr = HASH_REF eq ref $arg[0] ? $arg[0] : $arg[1];
    HASH_REF eq ref $fmtr
	or $self->wail(
	'Formatter definition must be a HASH reference' );
    defined( my $fmtr_name = $fmtr->{name} )
	or $self->wail(
	    'Formatter definition must have {name} defined' );
    $self->{formatter_method}{$fmtr_name}
	and $self->{warner}->wail(
	"Formatter method $fmtr_name already exists" );
    Astro::App::Satpass2::FormatValue->can( $fmtr_name )
	and $self->{warner}->wail(
	"Formatter $fmtr_name can not override built-in formatter" );
    $self->{formatter_method}{$fmtr_name} =
    Astro::App::Satpass2::FormatValue::Formatter->new( $fmtr );
    return $self;
}

sub attribute_names {
    my ( $self ) = @_;
    return ( $self->SUPER::attribute_names(),
	qw{ permissive },
    );
}

sub config {
    my ( $self, %args ) = @_;
    my @data = $self->SUPER::config( %args );

    # TODO support for the {default} key.

    foreach my $name (
	sort $args{changes} ?
	    keys %{ $self->{canned_template} } :
	    $self->__list_templates()
    ) {
	push @data, [ template => $name,
	    $self->{canned_template}{$name} ];
    }

    return wantarray ? @data : \@data;
}

# Return the names of all known templates, in no particular order. No
# arguments other than the invocant.
sub __list_templates {
    my ( $self ) = @_;
    return ( _uniq( map { keys %{ $_ } } $self->{canned_template},
	    __localize(
		text	=> '+template',
		default	=> {},
	    ) ) );
}

{
    my %decoder = (
	template	=> sub {
	    my ( $self, $method, @args ) = @_;

=begin comment

	    1 == @args
		and return ( @args, $self->$method( @args ) );
	    $self->$method( @args );
	    return $self;

=end comment

=cut

	    1 == @args
		or return $self->$method( @args );
	    return ( @args, $self->$method( @args ) );
	},
    );

    sub decode {
	my ( $self, $method, @args ) = @_;
	my $dcdr = $decoder{$method}
	    or return $self->SUPER::decode( $method, @args );
	goto $dcdr;
    }
}

sub __default {
    my ( $self, @arg ) = @_;
    @arg or return $self->{default};
    my $action = shift @arg;
    @arg or return $self->{default}{$action};
    my $attrib = shift @arg;
    defined $attrib
	or return delete $self->{default}{$action};
    @arg or return $self->{default}{$action}{$attrib};
    my $value = shift @arg;
    defined $value
	or return delete $self->{default}{$action}{$attrib};
    $self->{default}{$action}{$attrib} = $value;
    return $value;
}

sub format : method {	## no critic (ProhibitBuiltInHomonyms)
    my ( $self, %data ) = @_;

    exists $data{data}
	and $data{data} = $self->_wrap(
	    data	=> $data{data},
	    report	=> $data{template},
	);

    _is_format() and return $data{data};

    my $tplt = delete $data{template}
	or $self->wail( 'template argument is required' );

    my $tplt_name = SCALAR_REF eq ref $tplt ? ${ $tplt } : $tplt;

    $data{default} ||= $self->__default();

    $data{instantiate} = sub {
	my @args = @_;
	my $class = Astro::App::Satpass2::Utils::load_package( @args );
	return $class->new();
    };

    $data{provider} ||= $self->provider();

    if ( $data{time} ) {
	ref $data{time}
	    or $data{time} = $self->_wrap(
		data => { time => $data{time} },
		report	=> $tplt_name,
	    );
    } else {
	$data{time} = $self->_wrap(
	    data	=> { time => time },
	    report	=> $tplt_name,
	);
    }

    my $value_formatter = $self->value_formatter();

    $data{title} = $self->_wrap(
	default	=> $data{default},
	report	=> $tplt_name,
    );
    $data{TITLE_GRAVITY_BOTTOM} =
	$value_formatter->TITLE_GRAVITY_BOTTOM;
    $data{TITLE_GRAVITY_TOP} =
	$value_formatter->TITLE_GRAVITY_TOP;

    local $Template::Stash::LIST_OPS->{bodies} = sub {
	my ( $list ) = @_;
	return [ map { $_->body() } @{ $list } ];
    };

    local $Template::Stash::LIST_OPS->{events} = sub {
	my @args = @_;
	return $self->_all_events( @args );
    };

    local $Template::Stash::LIST_OPS->{fixed_width} = sub {
	my ( $list, $value ) = @_;
	foreach my $item ( @{ $list } ) {
	    my $code = $item->can( 'fixed_width' )
		or next;
	    $code->( $item, $value );
	}
	return;
    };

    $data{localize} = sub {
	return _localize( $tplt_name, @_ );
    };

    my $output = $self->_process( $tplt, %data );

    # TODO would love to use \h here, but that needs 5.10.
    $output =~ s/ [ \t]+ (?= \n ) //sxmg;
    $data{title}->title_gravity() eq $data{TITLE_GRAVITY_BOTTOM}
	and $output =~ s/ \A \n //smx;

    return $output;
}

sub gmt {
    my ( $self, @args ) = @_;
    if ( @args ) {
	$self->time_formatter()->gmt( @args );
	return $self->SUPER::gmt( @args );
    } else {
	return $self->SUPER::gmt();
    }
}

sub local_coord {
    my ( $self, @args ) = @_;
    if ( @args ) {
	my $val = $args[0];
	defined $val
	    or $val = $self->DEFAULT_LOCAL_COORD;

	defined $self->template( $val )
	    or $self->wail(
		'Unknown local coordinate specification', $val );

	return $self->SUPER::local_coord( @args );
    } else {
	return $self->SUPER::local_coord();
    }
}

sub permissive {
    my ( $self, @args ) = @_;
    if ( @args ) {
	if ( $self->{permissive} xor $args[0] ) {
	    $self->_new_tt( $args[0] );
	}
	$self->{permissive} = $args[0];
	return $self;
    } else {
	return $self->{permissive};
    }
}

sub template {
    my ( $self, $name, @value ) = @_;
    defined $name
	or $self->wail( 'Template name not specified' );

    if ( @value ) {
	my $tplt_text;
	if ( ! defined $value[0]
	    || defined( $tplt_text = __localize(
		    text	=> '+template',
		    default	=> $value[0] )
	    )
	    && $value[0] eq $tplt_text
	) {
	    delete $self->{canned_template}{$name};
	} else {
	    $self->{canned_template}{$name} = $value[0];
	}

	return $self;
    } else {
	defined $self->{canned_template}{$name}
	    and return $self->{canned_template}{$name};
	return __localize(
	    text	=> [ '+template', $name ],
	);
    }
}

sub tz {
    my ( $self, @args ) = @_;
    if ( @args ) {
	my $tf = $self->time_formatter();
	# We go through the following because the time formatter may
	# modify the zone (e.g. if it's using DateTime, zones are
	# case-sensitive so we may have done case conversion before
	# storing). We want this object to have the time formatter's
	# version of the zone.
	$tf->tz( @args );
	return $self->SUPER::tz( $tf->tz() );
    } else {
	return $self->SUPER::tz();
    }
}

sub _all_events {
    my ( $self, $data ) = @_;
    ARRAY_REF eq ref $data or return;

    my @events;
    foreach my $pass ( @{ $data } ) {
	push @events, $pass->__raw_events();
    }
    @events or return;
    @events = sort { $a->{time} <=> $b->{time} } @events;

    return [ map { $self->_wrap( data => $_ ) } @events ];
}

#	_is_format()
#
#	Returns true if the format() method is above us on the call
#	stack, otherwise returns false.

use constant REPORT_CALLER => __PACKAGE__ . '::format';
sub _is_format {
    my $level = 2;	# Start with caller's caller.
    while ( my @info = caller( $level ) ) {
	REPORT_CALLER eq $info[3]
	    and return $level;
	$level++;
    }
    return;
}

sub _localize {
    my ( $report, $source, $default ) = @_;
    defined $default
	or $default = $source;
    defined $report
	or return defined $source ? $source : $default;

    return scalar __localize(
	text	=> [ "-$report", 'string', $source ],
	default	=> $source,
    );
}

sub _process {
    my ( $self, $tplt, %arg ) = @_;
    ARRAY_REF eq ref $arg{arg}
	and $arg{arg} = Astro::App::Satpass2::Wrap::Array->new(
	$arg{arg} );
    my $output;
    my $tt = $self->{tt};

    my $tplt_text;
    not ref $tplt
	and defined( $tplt_text = $self->template( $tplt ) )
	and $tplt = \$tplt_text;

    $tt->process( $tplt, \%arg, \$output )
	or $self->wail( $tt->error() );
    return $output;
}

# Cribbed shamelessly from List::MoreUtils. The author reserves the
# right to relocate, rename or otherwise mung with this without notice
# to anyone. Caveat user.
sub _uniq {
    my %found;
    return ( grep { ! $found{$_}++ } @_ );
}

sub _wrap {
    my ( $self, %arg ) = @_;

    my $data = $arg{data};
    my $default = $arg{default};
    my $report = $arg{report};

    my $title = ! $data;
    $data ||= {};
    $default ||= $self->__default();

    if ( instance( $data, 'Astro::App::Satpass2::FormatValue' ) ) {
	# Do nothing
    } elsif ( ! defined $data || HASH_REF eq ref $data ) {
	my $value_formatter = $self->value_formatter();
	$data = $value_formatter->new(
	    data	=> $data,
	    default	=> $default,
	    date_format => $self->date_format(),
	    desired_equinox_dynamical =>
			    $self->desired_equinox_dynamical(),
	    provider	=> $self->provider(),
	    round_time	=> $self->round_time(),
	    time_format => $self->time_format(),
	    time_formatter => $self->time_formatter(),
	    local_coordinates => sub {
		my ( $data, @arg ) = @_;
		return $self->_process( $self->local_coord(),
		    data	=> $data,
		    arg		=> \@arg,
		    title	=> $self->_wrap(
			default	=> $default,
			report	=> $report,
		    ),
		    localize	=> sub {
			return _localize( $report, @_ );
		    },
		);
	    },
	    list_formatter => sub {
		my ( $data, @arg ) = @_;
		my $body = $data->body();
		my $list_type = $body ? $body->__list_type() : 'inertial';
		return $self->_process( "list_$list_type",
		    data	=> $data,
		    arg		=> \@arg,
		    title	=> $self->_wrap(
			default => $default,
			report	=> $report,
		    ),
		);
	    },
	    report	=> $report,
	    title	=> $title,
	    warner	=> $self->warner(),
	);
	$data->add_formatter_method( values %{ $self->{formatter_method} } );
    } elsif ( ARRAY_REF eq ref $data ) {
	$data = [ map { $self->_wrap( data => $_, report => $report ) } @{ $data } ];
    } elsif ( embodies( $data, 'Astro::Coord::ECI' ) ) {
	$data = $self->_wrap(
	    data	=> { body => $data },
	    report	=> $report,
	);
    }

    return $data;
}

__PACKAGE__->create_attribute_methods();

1;

__END__

=head1 NAME

Astro::App::Satpass2::Format::Template - Format Astro::App::Satpass2 output as text.

=head1 SYNOPSIS

 use strict;
 use warnings;
 
 use Astro::App::Satpass2::Format::Template;
 use Astro::Coord::ECI;
 use Astro::Coord::ECI::Moon;
 use Astro::Coord::ECI::Sun;
 use Astro::Coord::ECI::Utils qw{ deg2rad };
 
 my $time = time();
 my $moon = Astro::Coord::ECI::Moon->universal($time);
 my $sun = Astro::Coord::ECI::Sun->universal($time);
 my $station = Astro::Coord::ECI->new(
     name => 'White House',
 )->geodetic(
     deg2rad(38.8987),  # latitude
     deg2rad(-77.0377), # longitude
     17 / 1000);	# height above sea level, Km
 my $fmt = Astro::App::Satpass2::Format::Template->new();
 
 print $fmt->location( $station );
 print $fmt->position( {
	 bodies => [ $sun, $moon ],
	 station => $station,
	 time => $time,
     } );

=head1 DETAILS

This class is intended to perform output formatting for
L<Astro::App::Satpass2|Astro::App::Satpass2>, producing output similar
to that produced by the F<satpass> script distributed with
L<Astro::Coord::ECI|Astro::Coord::ECI>. It is a subclass of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and
conforms to that interface.

The L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>
interface specifies a set of methods corresponding (more or less) to the
interactive methods of L<Astro::App::Satpass2|Astro::App::Satpass2>.
This class implements those methods in terms of a canned set of
L<Template-Toolkit|Template> templates, with the data from the
L<Astro::App::Satpass2|Astro::App::Satpass2> methods wrapped in
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects to provide formatting at the field level.

The names and contents of the templates used by each formatter are
described with each formatter. The templates may be retrieved or
modified using the L<template()|/template> method.

=head1 METHODS

This class supports the following public methods. Methods inherited from
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format> are
documented here if this class adds significant functionality.

=head2 Instantiator

=head3 new

 $fmt = Astro::App::Satpass2::Format::Template->new();

This static method instantiates a new formatter.

=head2 Accessors and Mutators

=head3 local_coord

 print 'Local coord: ', $fmt->local_coord(), "\n";
 $fmt->local_coord( 'azel_rng' );

This method overrides the
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>
L<local_coord()|Astro::App::Satpass2::Format/local_coord> method, and
performs the same function.

Out of the box, legal values for this are consistent with the
superclass' documentation; that is, C<'az_rng'>, C<'azel'>,
C<'azel_rng'>, C<'equatorial'>, and C<'equatorial_rng'>. These are
actually implemented as templates, as follows:

    az_rng        => <<'EOD',
    [% data.azimuth( arg, bearing = 2 ) %]
        [%= data.range( arg ) -%]
    EOD
 
    azel        => <<'EOD',
    [% data.elevation( arg ) %]
        [%= data.azimuth( arg, bearing = 2 ) -%]
    EOD
 
    azel_rng        => <<'EOD',
    [% data.elevation( arg ) %]
        [%= data.azimuth( arg, bearing = 2 ) %]
        [%= data.range( arg ) -%]
    EOD
 
    equatorial        => <<'EOD',
    [% data.right_ascension( arg ) %]
        [%= data.declination( arg ) -%]
    EOD
 
    equatorial_rng        => <<'EOD',
    [% data.right_ascension( arg ) %]
        [%= data.declination( arg ) %]
        [%= data.range( arg ) -%]
    EOD

These definitions can be changed, or new local coordinates added, using
the L<template()|/template> method.

=head3 permissive

 print 'Formatter is ', $fmt->permissive() ? "permissive\n" : "not
permissive\n";
 $fmt->permissive( 1 );

This method is accessor and mutator for the C<permissive> attribute.
This attribute controls whether C<Template-Toolkit> is permissive in the
matter of what files it will load. By default it will only load files
specified by relative paths without the 'up-directory' specification
(F<..> under *nix). If true, absolute paths, and path containing the
'up-directory' specification are allowed.

If called with no argument, this method is an accessor, and returns the
current value of the attribute.

If called with an argument, this method is a mutator, and sets a new
value of the attribute. In this case, the invocant is returned.

The default is false, because that is the C<Template-Toolkit> default.
The reason for this is (in terms of this module)

 $fmt->format( template => '/etc/passwd' );

=head2 Formatters

As stated in the
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>
documentation, there is actually only one formatter method:

=head3 format

  print $fmtr->format( template => 'location', data => $sta );

This formatter implements the C<format()> method using
L<Template-Toolkit|Template>.  The C<template> argument is required, and
selects one of the canned templates provided. The C<data> argument is
required unless your templates are capable of calling
L<Astro::App::Satpass2|Astro::App::Satpass2> methods on their own
account, and must (if provided) be whatever is expected by the template.
See L<Templates|/Templates> below for the details.

This method can also execute an arbitrary template if you pass an
L<Astro::App::Satpass2|Astro::App::Satpass2> object in the C<sp>
argument. These templates can call methods on the C<sp> object to
generate their data. If a method which calls the C<format()> method on
its own behalf (like C<almanac()>) is called on the C<sp> object, the
recursive call is detected, and the data are passed back to the calling
template. If arguments for L<Astro::App::Satpass2|Astro::App::Satpass2>
methods are passed in, it is strongly recommended that they be passed in
the C<arg> argument.

Except for the C<template> argument, all named arguments to C<format()>
are provided to the template. In addition, the following arguments will
be provided:

=over

=item instantiate

You can pass one or more class names as arguments. The argument is a
class name which is loaded by the
L<Astro::App::Satpass2::Utils|Astro::App::Satpass2::Utils>
L<load_package()|Astro::App::Satpass2::Utils/load_package> subroutine.
If the load succeeds, an object is instantiated by calling C<new()> on
the loaded class name, and that object is returned. If no class can be
loaded an exception is thrown.

=item localize

This is a code reference to localization code. It takes two arguments:
the string to localize, and an optional default if the string can not be
localized for some reason. The second argument defaults to the first.  A
typical use would be something like

 [% localize( 'Location' ) %]

The localization comes from the locale system, specifically from key
C<{"-$template"}{string}{$string}>, where C<$template> is the name of
the main template being used, and C<$string> is the string to localize.

=item provider

This is simply the value returned by
L<provider()|Astro::App::Satpass2::Format/provider>.

=item time

This is the current time wrapped in an
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
object.

=item title

This is an
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
configured to produce field titles rather than data.

=item TITLE_GRAVITY_BOTTOM

This manifest constant is defined in
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>.
See the
L<title_gravity()|Astro::App::Satpass2::FormatValue/title_gravity>
documentation for the details.

If the C<title> object has its C<title_gravity()> set to this value
after template processing, and the output of the template has a leading
newline, that newline is removed. See the
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
L<title_gravity()|Astro::App::Satpass2::FormatValue/title_gravity>
documentation for why this hack was imposed on the output.

=item TITLE_GRAVITY_TOP

This manifest constant is defined in
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>.
See the
L<title_gravity()|Astro::App::Satpass2::FormatValue/title_gravity>
documentation for the details.

=back

In addition to any variables passed in, the following array methods are
defined for C<Template-Toolkit> before it is invoked:

=over

=item bodies

If called on an array of objects, returns a reference to the results of
calling body() on each of the objects. This is good for (e.g.)
recovering a bunch of L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE>
objects from their containing
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects.

=item events

If called on an array of passes, returns all events in all passes, in
chronological order.

=item fixed_width

If called on an array of
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects, calls
L<fixed_width()|Astro::App::Satpass2::FormatValue/fixed_width> on them.
You may specify an argument to C<fixed_width()>.

Nothing is returned.

=back

=head3 add_formatter_method

 $tplt->add_formatter_method( \%definition );

This experimental method adds the named formatter to any
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects created. The argument is a reference to a hash that defines the
format. The name of the formatter must appear in the C<{name}> element
of the hash, and this name may not duplicate any formatter built in to
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>,
nor any formatter previously added by this method. The other elements in
the hash are purposefully left undocumented until the whole business of
adding a formatter becomes considerably less wooly and experimental.

What this really does is instantiate a
L<Astro::App::Satpass2::FormatValue::Formatter|Astro::App::Satpass2::FormatValue::Formatter>
and add that object to any
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects created.

=head2 Templates

The required values of the C<template> argument are supported by
same-named L<Template-Toolkit|Template> templates, as follows. The
C<data> provided should be as described in the documentation for the
L<Astro::App::Satpass2|Astro::App::Satpass2>
L<formatter()|Astro::App::Satpass2/formatter> method. If the C<data> value is
not provided, each of the default templates will call an appropriate
L<Astro::App::Satpass2|Astro::App::Satpass2> method on the C<sp> value,
passing it the C<arg> value as arguments.

The following documentation no longer shows the default templates, since
it has proven difficult to maintain. Instead it simply (and probably
more helpfully) documents the circumstances under which each template is
used. If you wish to display a default template you can do something
like the following:

 $ satpass2 -initfile /dev/null
 satpass2> # Display the 'almanac' template
 satpass2> formatter -raw template almanac

Specifying the null device for -initfile ensures you get the default
template, rather than one your own initialization file may have loaded.
The example is for a Unix system; Windows and VMS users should
substitute something appropriate. The C<-raw> simply displays the value,
rather than formatting it as a command to set the value.

=head3 almanac

This template is used by the C<almanac()> and C<quarters()> methods.

=head3 flare

This template is used by the C<flare()> method.

=head3 list

This template is used by the C<list()> method.

=head3 location

This template is used by the C<location()> method.

=head3 pass

This template is used by the C<pass()> method, unless the C<-events>
option is specified.

=head3 pass_events

This template is used by the C<pass()> method if the C<-events> option
is specified. It orders events chronologically without respect to their
source.

=head3 phase

This template is used by the C<phase()> method.

=head3 position

This template is used by the C<position()> method.

=head3 tle

This template is used by the C<tle()> method, unless C<-verbose> is
specified. Note that the default template does not generate a trailing
newline, since the result of the body's C<tle()> method is assumed to
provide this.

=head3 tle_verbose

This template is used by the C<tle()> method if C<-verbose> is
specified. It is assumed to provide some sort of formatted version of
the TLE.

=head2 Other Methods

The following other methods are provided.

=head2 decode

 $fmt->decode( format_effector => 'azimuth' );

This method overrides the L<Astro::App::Satpass2::Format
decode()|Astro::App::Satpass2::Format/decode> method. In addition to
the functionality provided by the parent, the following methods return
something different when invoked via this method:

=over

=item format_effector

If called as an accessor, the name of the formatter accessed is
prepended to the returned array. If this leaves the returned array with
just one entry, the string C<'undef'> is appended. The return is still
an array in list context, and an array reference in scalar context.

If called as a mutator, you still get back the object reference.

=back

If a subclass overrides this method, the override should either perform
the decoding itself, or delegate to C<SUPER::decode>.

=head3 format

 $fmt->format( template => $template, ... );

This method represents the interface to L<Template-Toolkit|Template>,
and all the formatter methods come through here eventually.

The arguments to this method are name/value pairs. The C<template>
argument is required, and is either the name of a template file, or a
reference to a string containing the template. All other arguments are
passed to C<Template-Toolkit> as variables. If argument C<arg> is
specified and its value is an array reference, the value is enclosed in
an
L<Astro::App::Satpass2::Wrap::Array|Astro::App::Satpass2::Wrap::Array>
object, since by convention this is the argument passed back to
L<Astro::App::Satpass2|Astro::App::Satpass2> methods.

In addition to any variables passed in, the following array methods are
defined for C<Template-Toolkit> before it is invoked:

=over

=item events

If called on an array of passes, returns all events in all passes, in
chronological order.

=item fixed_width

If called on an array of
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
objects, calls
L<fixed_width()|Astro::App::Satpass2::FormatValue/fixed_width> on them.
You may specify an argument to C<fixed_width()>.

Nothing is returned.

=back

The canned templates can also be run as reports, and in fact will be
taken in preference to files of the same name. If you do this, you will
need to pass the relevant L<Astro::App::Satpass2|Astro::App::Satpass2>
object as the C<sp> argument, since by convention the canned templates
all look to that variable to compute their data if they do not already
have a C<data> variable.

=head3 template

 print "Template 'almanac' is :\n", $fmt->template( 'almanac' );
 $fmt->template( almanac => <<'EOD' );
 [% UNLESS data %]
     [%- SET data = sp.almanac( arg ) %]
 [%- END %]
 [%- FOREACH item IN data %]
     [%- item.date %] [% item.time %]
         [%= item.almanac( units = 'description' ) %]
 [% END -%]
 EOD

This method is not inherited from
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>.

If called with a single argument (the name of a template) this method is
an accessor that returns the named template. If the named template does
not exist, this method croaks.

If called with two arguments (the name of a template and the template
itself), this method is a mutator that sets the named template. If the
template is C<undef>, the named template is deleted. The object itself
is returned, to allow call chaining.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
