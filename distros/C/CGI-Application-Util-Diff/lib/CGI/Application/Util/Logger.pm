package CGI::Application::Util::Logger;

use Carp;

use Config::Tiny;

use DBI;

use Hash::FieldHash qw/:all/;

fieldhash my %config  => 'config';
fieldhash my %dbh     => 'dbh';
fieldhash my %section => 'section';

use Path::Class; # For file().

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Application::Util::Logger ':all';
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
	 _config_file => '',
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

sub get_dir_name
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'dir_name'};

} # End of get_dir_name.

# -----------------------------------------------

sub get_file_name
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'file_name'};

} # End of get_file_name.

# -----------------------------------------------

sub get_verbose
{
	my($self) = @_;

	return ${$self -> config()}{$self -> section()}{'verbose'};

} # End of get_verbose.

# -----------------------------------------------

sub init
{
	my($self)      = @_;
	my($file_name) = file($self -> get_dir_name(), $self -> get_file_name() );

	$self -> dbh(DBI -> connect('DBI:CSV:f_dir=' . $self -> get_dir_name() ) );

	if (-e $file_name)
	{
		$self -> dbh() -> do('drop table ' . $self -> get_file_name() );
	}

	$self ->
		dbh() ->
		prepare('create table ' . $self -> get_file_name() . '(message varchar(255) )') ->
		execute();

} # End of init.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	if ($self -> get_verbose() )
	{
		$self ->
			dbh() ->
			prepare('insert into ' . $self -> get_file_name() . ' (message) values (?)') ->
			execute(scalar localtime() . ': ' . ($s || '') );
	}

} # End of log.

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

	# Read the user-supplied or default config file.

	my($path) = $$self{'_config_file'};

	if (! $path)
	{
		my($name) = '.htutil.logger.conf';

		for (keys %INC)
		{
			next if ($_ !~ m|CGI/Application/Util/Logger.pm|);

			($path = $INC{$_}) =~ s/Logger.pm/$name/;
		}
	}

	# Check [logger].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('logger');

	if (! ${$self -> config()}{$self -> section()})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section()]}]";
	}

	$self -> init();

	return $self;

}	# End of new.

# --------------------------------------------------

1;
