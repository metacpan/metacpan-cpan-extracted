package Catalyst::Plugin::DBIC::ConsoleQueryLog;

use Moo::Role;
use Catalyst::Utils;
use Text::SimpleTable;

our $VERSION = '0.002';

my $_model_name = '';
my $model_name = sub {
  my $c = shift;
  return $_model_name ||= do {
    if(my $config = $c->config->{'Plugin::DBIC::ConsoleQueryLog'}) {
      $config->{'model_name'};
    } else {
      undef;
    }
  };
};

my $model = sub {
  my $c = shift;
  my $model = $c->model($c->$model_name);
  if($model) {
    return $model;
  } else {
    $c->log->info("You specified a model '$model_name' but I can't find it.") if $model_name;
    return;
  }
};

my $querylog = sub {
  my $c = shift;
  my $model = $c->$model || return;
  if($model->can('querylog')) {
    return $model->querylog;
  } else {
    $c->log->info("You requested querylog for model $model but there's no querylog_analyzer");
    return;
  }
};

my $time_elapsed = sub {
  my $c = shift;
  return ($c->$querylog || return)->time_elapsed;
};

my $query_count = sub {
  my $c = shift;
  return ($c->$querylog || return)->count;
};

my $querylog_analyzer = sub {
  my $c = shift;
  my $model = $c->$model || return;
  if($model->can('querylog_analyzer')) {
    return $model->querylog_analyzer;
  } else {
    $c->log->info("You requested querylog_analyzer for model $model but there's no querylog_analyzer");
    return;
  }
};

my $sorted_queries = sub {
  my $c = shift;
  my @sorted_queries = @{($c->$querylog_analyzer||return)
    ->get_sorted_queries ||[]};
  return @sorted_queries;
};

after 'finalize', sub {
  return unless (my $c = shift)->debug;
  my $t = $c->querylog_table;
  my @sorted_queries = $c->$sorted_queries;
  foreach my $q (@sorted_queries) {
    $c->add_querylog_table_row($t, $q);
  }
  my $count = $c->$query_count;
  my $time = sprintf('%0.6fs', $c->$time_elapsed);
  my $q_display = $count > 1 ? 'queries':'query';
  $c->log->info( "SQL Profile Data ($count $q_display / $time elapsed time):\n" . $t->draw . "\n" ) if @sorted_queries;
};

sub querylog_table {
  my $column_width = Catalyst::Utils::term_width() - 6 - 16;
  my $t = Text::SimpleTable->new( [ $column_width, 'SQL' ], [ 9, 'Time' ] );
  return $t;
};

sub add_querylog_table_row {
  my ($c, $t, $q) = @_;
  my $q_sql = $q->sql . ' : ' . join(', ', @{$q->params||[]});
  my $q_total = sprintf('%0.6fs', $q->time_elapsed);
  $t->row($q_sql, $q_total);
};

=head1 NAME
 
Catalyst::Plugin::DBIC::ConsoleQueryLog - Log DBIC queries and timings to the console

=head1 SYNOPSIS
 
Use the plugin in your application class:
 
    package MyApp;

    use Catalyst qw/DBIC::ConsoleQueryLog/;

    __PACKAGE__->config(
      'Plugin::DBIC::ConsoleQueryLog' => { model_name => 'Schema' },
      'Model::Schema' => { # This is a model of Catalyst::Model::DBIC::Schema
        schema_class => 'MyApp::Schema',
        traits => ['QueryLog'], # Please note you NEED to use this trait.
      },
    );

    __PACKAGE__->setup;
 
=head1 DESCRIPTION
 
This is a very basic console logger for L<DBIx::Class::QueryLog::Analyzer>, which you
might be using in L<Catalyst> via L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
in order to get tracing and performance information on you SQL calls.  You must be
using L<Catalyst::Model::DBIC::Schema> and have added the L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
trait in configuration as in the L</SYNOPSIS> example.

I wrote this because I got tired of adding it manually over and over to my basic
application framework.  However its a very basic logger that doesn't support some of
the more powerful bits such as creating buckets to classify you logging, etc.  It will
get you started but eventually you'll need to roll your own as you needs become more complex.

Console logging will only occur when the application is run in debug mode.  I recommend
only adding this plugin in development since it's needless overhead in production.

=head1 METHOD

This plugin exposes the following public methods.

=head2 querylog_table

Returns an instance of L<Text::SimpleTable> that is setup to display the rows of querylog
information.  You can override this if you trying to customize the querylog information.

=head2 add_querylog_table_row

Receives an instance of L<Text::SimpleTable>, and L<DBIx::Class::QueryLog::Analyzer> so
that you can customize drawing a row of data.  Override if you are adding custom display
information.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
   
=head1 SEE ALSO
  
L<DBIx::Class>, L<DBIx::Class::QueryLog>, L<DBIx::Class::QueryLog::Analyzer>, L<Catalyst>,
L<Catalyst::Model::DBIC::Schema>, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>,
 
=head1 COPYRIGHT & LICENSE
  
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
  
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
  
=cut

1;
