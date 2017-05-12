package
  t::TestUtils;

use strict;
use warnings;
use File::Spec ();
use File::Copy ();
use Cwd ();
use Test::Requires 'DBD::SQLite';

use parent qw/Exporter/;
our @EXPORT = qw/ $dsn schema process_wrap process_wrap_xml runner /;

my ($_schema, $_attr);
our ($dsn, $user, $password, $DEBUG) = 
    @ENV{map { "BPMTEST_${_}" } qw/DSN USER PASS KEEP/};

if($dsn && $user && !$DEBUG) {
    $_attr = { RaiseError => 1, AutoCommit => 1 };
    }
else {
    $dsn = $DEBUG ?
        'dbi:SQLite:dbname=t/var/bpmengine.db' : 'dbi:SQLite::memory:';
    $user = '';
    $password = '';
    $_attr = { sqlite_unicode => 1 };    
    }

sub _local_db {
    my $db_file = './t/var/bpmengine.db';
    if(-f $db_file) {
        unlink $db_file or warn "Could not unlink $db_file: $!";
        }
    my (undef, $path) = File::Spec->splitpath(__FILE__);
    $path = Cwd::abs_path($path);
    my $scaffold_db = File::Spec->catfile($path, 'var', 'bpmengine.test.db');
    die("Scaffold database not found") unless -f $scaffold_db;
    File::Copy::copy($scaffold_db, $db_file) or die "Copy failed: $!";
    }

sub schema {
    unless($_schema) {
        _local_db() if $DEBUG;
        eval "require BPM::Engine::Store" 
            or die "failed to require schema: $@";
        $_schema = BPM::Engine::Store->connect($dsn, $user, $password, $_attr) 
            or die "failed to connect to $dsn";
        $_schema->deploy({ add_drop_table => $_attr->{sqlite_unicode} ? 0 : 1 }) 
            unless $DEBUG;
        }
    
    return $_schema;
    }

sub process_wrap_xml {
    my ($xml, $pack, $v) = @_;

    $xml  ||= '';
    $v    ||= 2.1;
    $pack ||= '';

    $xml = q|<?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://www.wfmc.org/2008/XPDL2.1" Id="TestPackage">
        <PackageHeader><XPDLVersion>| . $v . q|</XPDLVersion>
        <Vendor/><Created/></PackageHeader>|
         . $pack . '<WorkflowProcesses><WorkflowProcess Id="TestProcess"><ProcessHeader/>'
         . $xml  . '</WorkflowProcess></WorkflowProcesses></Package>';
    
    return $xml;
    }

sub process_wrap {
    my (@args) = @_;
    
    my $xml = process_wrap_xml(@args);
    
    eval "require BPM::Engine" or die "failed to require engine: $@";

    my $engine = BPM::Engine->new(schema => schema());
    my $process = $engine->create_package(\$xml)->processes->first;

    return ($engine, $process);
    }

sub runner {
    my ($engine, $process, $args) = @_;

    unless(ref($process)) {
        $process = $engine->get_process_definition({ process_uid => $process })
            or die("Process $process not found");
        }
    my $i = $engine->create_process_instance($process);

    foreach(keys %{$args}) {
        $i->attribute($_ => $args->{$_});
        }

    return ($engine->runner($i), $process, $i);
    }

1;
__END__

=pod

=head1 NAME

t::TestUtils - Test utitily functions for BPM::Engine

=head1 SYNOPSIS

    use t::TestUtils;
    
    is($dsn, 'dbi:SQLite::memory:');    
    
    isa_ok(schema(), 'BPM::Engine::Store');
    schema()->resultset('Blah')->create({ blah => '123' });
    
    my ($engine, $process) = process_wrap($process_xml, $package_xml);
    
    my ($runner, $process, $instance) = runner($engine, $process_uid, \%args);
    my ($runner, $process, $instance) = runner( process_wrap($xml) );

=head1 DESCRIPTION

Test utility functions for L<BPM::Engine|BPM::Engine> tests. See the F<*.t> 
files for usage examples.

=head1 EXPORTED VARIABLE AND FUNCTIONS

=head2 $dsn

The dsn of the test database used.

=head2 schema

Creates a temporary SQLite database, deploys the 
L<BPM::Engine::Store|BPM::Engine::Store> schema, and then connects to it. 
Subsequent calls to C<schema()> will return the schema created on the first 
call. Since you have a fresh database for every test, you don't have to worry 
about cleaning up after your tests, ordering of tests affecting failure, etc.

Returns the L<BPM::Engine::Store|BPM::Engine::Store> instance connected and
deployed to the test database. When your program exits, the temporary in-memory 
database will go away, unless BPMTEST_KEEP is set.

=head2 process_wrap

Creates a BPM::Engine instance and imports a single-process Package, returns the
engine and the process result row.

    my ($engine, $process) = process_wrap($process_xml, $package_xml);

=head2 process_wrap_xml

Generates XPDL package definition for snippets of xml.

    my $xml = process_wrap_xml($process_xml, $package_xml);

=over

=item $process_xml

Optional xml string representing any XPDL child elements in the 
C<WorkflowProcess> after the C<ProcessHeader> element

=item $package_xml

Optional xml string representing any XPDL child elements coming after the 
C<PackageHeader> element in the C<Package> definition

=back

=head2 runner

Takes a L<BPM::Engine|BPM::Engine> object, a process_uid or a 
L<BPM::Engine::Store::Result::Process|BPM::Engine::Store::Result::Process> 
object and an optional hashref of processs instance arguments, and creates a
ProcessInstance result row. Returns a 
L<BPM::Engine::ProcessRunner|BPM::Engine::ProcessRunner> instance for the 
process instance, the Process result row and the ProcessInstance result row.

=head1 ENVIRONMENT

You can control the behavior of this module at runtime by setting
environment variables.

  BPMTEST_DSN=DBI:mysql:bpmengine
  BPMTEST_USER=root

=head2 BPMTEST_KEEP

If this variable is true, then the test database will not be deleted at C<END> 
time.  Instead, the database will be available as F<./t/var/bpmengine.db>.

This is useful if you want to look at the database your test generated, for 
debugging. Note that the database will never exist on disk if you don't set this
to a true value.

=head2 BPMTEST_DSN

If this variable is specified, this dsn will be connected to instead of the 
in-memory or temporary SQLite database. This will only be used if BPMTEST_KEEP 
is false, and at least the BPMTEST_USER is specified as well.

WARNING: This will drop all tables used on test deployment, and all data will be 
lost. You do NOT ever want to set this to the production database's dsn.

=head2 BPMTEST_USER

Username for the database connection specified by BPMTEST_DSN

=head2 BPMTEST_PASS

Password for the database connection specified by BPMTEST_DSN

=head1 AUTHOR

Peter de Vos C<< <sitetech@cpan.org> >>

=head1 LICENSE

Copyright (c) 2011 Peter de Vos.

This program is free software.  You may use, modify, and redistribute
it under the same terms as Perl itself.

=cut
