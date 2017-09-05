package Anego::Config;
use strict;
use warnings;
use utf8;
use File::Spec;
use DBI;

use Anego::Logger;

our $CONFIG_PATH;
our $CONFIG;

sub config_path { $CONFIG_PATH || './.anego.pl' }

sub load {
    my ($class) = @_;

    return $CONFIG if $CONFIG;

    my $config_path = $class->config_path;
    errorf("Could not find config file: $config_path\n") unless -f $config_path;

    my $config = do $config_path or errorf("Could not load config file: $@");
    $CONFIG = bless $config, $class;

    return $CONFIG;
}

sub schema_class { $_[0]->{schema_class} }
sub connect_info { $_[0]->{connect_info} }

sub database {
    my ($self) = @_;
    unless ($self->{database}) {
        $self->{database} = do { my (undef, $d) = $self->connect_info->[0] =~ /(database|dbname|name|db)=([\w:]+)/; $d };
    }
    return $self->{database};
}

sub schema_path  {
    my ($self) = @_;
    unless ($self->{schema_path}) {
        my @splited_schema_class = split /::/, $self->schema_class;
        my $basename = pop @splited_schema_class;

        $self->{schema_path} = File::Spec->catfile('lib', @splited_schema_class, "$basename.pm");
    }
    return $self->{schema_path};
}

sub rdbms {
    my ($self) = @_;
    unless ($self->{rdbms}) {
        my $dsn = $self->connect_info->[0];
        $self->{rdbms} = $dsn =~ /:mysql:/ ? 'MySQL'
                       : $dsn =~ /:Pg:/ ? 'PostgreSQL'
                       : do { my ($d) = $dsn =~ /dbi:(.*?):/; $d };
    }
    return $self->{rdbms};
}

sub dbh {
    my ($self) = @_;
    unless ($self->{dbh}) {
        $self->{dbh} = DBI->connect(@{ $self->connect_info });
    }
    return $self->{dbh};
}

1;
