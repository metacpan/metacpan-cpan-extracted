package Carrot::Individuality::Singular::Application::DBH
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use DBI;

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions',
		my $class_names = '::Individuality::Controlled::Class_Names',
		my $os_process = '::Individuality::Singular::Process::Id',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$distinguished_exceptions->provide(
		my $dsn_not_set = 'dsn_not_set',
		my $failed_connection = 'failed_connection');

	$class_names->provide(
		my $wrapper_class = '[=this_pkg=]::Wrapper');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$customized_settings->provide_plain_value(
		my $dsn = 'dsn',
		my $login = 'login',
		my $password = 'password');

	unless (defined($dsn) and length($dsn))
	{
		$dsn_not_set->raise_exception(
			{},
			ERROR_CATEGORY_SETUP);
	}
	$this->[ATR_CREDENTIALS] = [$dsn, $login, $password];
	$this->[ATR_CONNECTION] = IS_UNDEFINED;
	$this->[ATR_WRAPPED] = IS_UNDEFINED;

	$os_process->subscribe_pid_change($this);
	$this->connect;

	return;
}

sub connection
# /type method
# /effect ""
# //parameters
# //returns
#	::Meta::Role::Instance
{
	return($_[THIS][ATR_CONNECTION]);
}

sub wrapped
# /type method
# /effect ""
# //parameters
# //returns
#	::Meta::Role::Instance
{
	return($_[THIS][ATR_WRAPPED]);
}

sub connect
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $connection = DBI->connect(@{$this->[ATR_CREDENTIALS]});
	unless (defined($connection))
	{
		$failed_connection->raise_exception(
			{'error' => $DBI::errstr},
			ERROR_CATEGORY_SETUP);
	}
	$this->[ATR_CONNECTION] = $connection;
	$this->[ATR_WRAPPED] = $wrapper_class->indirect_constructor($connection);

	return;
}

sub disconnect
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless (defined($this->[ATR_CONNECTION]));
	$this->[ATR_CONNECTION]->disconnect();
	$this->[ATR_CONNECTION] = IS_UNDEFINED;
	$this->[ATR_WRAPPED] = IS_UNDEFINED;

	return;
}

#FIXME: dis- and re-connection are problems, because $dbh doesn't change
# even IF $dbh would change, still the prepared statements might be invalid
#FIXME: maybe one of the biggest known bugs
sub evt_pid_change
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if (defined($this->[ATR_CONNECTION]))
	{
		$this->connect;
	}
	return;
}

sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$os_process->unsubscribe_pid_change($this);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.59
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"