package CGI::Application::Util::Diff::Config;

use Carp;

use Config::Tiny;

use Hash::FieldHash qw/:all/;

fieldhash my %config  => 'config';
fieldhash my %section => 'section';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Application::Util::Diff::Config ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.03';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub get_form_action
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'form_action'};

} # End of get_form_action.

# -----------------------------------------------

sub get_logger
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'logger'};

} # End of get_logger.

# -----------------------------------------------

sub get_temp_dir
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'temp_dir'};

} # End of get_temp_dir.

# -----------------------------------------------

sub get_tmpl_path
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'tmpl_path'};

} # End of get_tmpl_path.

# -----------------------------------------------

sub get_yui_url
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'yui_url'};

} # End of get_yui_url.

# -----------------------------------------------

sub new
{
	my($class, $arg) = @_;
	my($self)        = bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($$arg{$arg_name}) )
		{
			$$self{$attr_name} = $$arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	my($name) = '.htutil.diff.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|CGI/Application/Util/Diff/Config.pm|);

		($path = $INC{$_}) =~ s/Config.pm/$name/;
	}

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('global');

	if (! ${$self -> config()}{$self -> section()})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section()]}]";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config()}{$self -> section()}{'host'});

	if (! ${$self -> config()}{$self -> section()})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section()]}]";
	}

	return $self;

}	# End of new.

# --------------------------------------------------

1;
