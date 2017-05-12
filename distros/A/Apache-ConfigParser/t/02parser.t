#!/usr/bin/perl -w
#
# Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.

$| = 1;

use strict;
use Test::More tests => 111;

BEGIN { use_ok('Apache::ConfigParser'); }

# Cd into t if it exists.
chdir 't' if -d 't';

package EmptySubclass;
use Apache::ConfigParser;
use vars qw(@ISA);
@ISA = qw(Apache::ConfigParser);
package main;

# Find all of the httpd\d{2}.conf files.
my @conf_files = glob('httpd[0-9][0-9].conf');
is(@conf_files, 8, 'eight httpd\d{2}.conf files found');

# A parser should be created when no arguments are passed in.  An
# error should be returned if an non-existent file is passed to
# parse_file.
{
  my $c = EmptySubclass->new;
  ok($c, 'Apache::ConfigParser created for no configuration file');
  isa_ok($c, 'EmptySubclass');
  my $rc = $c->parse_file('non-existent file');
  ok(!$rc, 'Apache::ConfigParser->parse_file fails for non-existent file');
  my $regex = "cannot stat 'non-existent file':";
  $rc = $c->errstr =~ /$regex/o;
  ok($rc, "Apache::ConfigParser->errstr matches regex \"$regex\"");
}

# This subroutine just modifies the passed string to make sure that
# this string does not show up in particular output.  Do not do this
# to DocumentRoot and ServerRoot.
sub post_transform_munge {
  is(@_, 5, 'post_transform_munge passed 5 arguments');
  my ($parser, $directive, $filename) = @_;

  if ($directive eq 'documentroot' or $directive eq 'serverroot') {
    return $filename;
  }

  "MUNGE $filename";
}

# This is the subroutine that will modify any filenames.  Trim off any
# directory names in the filename, except for DocumentRoot and
# ServerRoot.
sub post_transform_path {
  is(@_, 3, 'post_transform_path passed 3 arguments');

  my ($parser, $directive, $filename) = @_;

  if ($directive eq 'documentroot' or $directive eq 'serverroot') {
    return $filename;
  }

  my @elements = split(m#/#, $filename);
  $elements[-1];
}

# This is the option to pass to the constructor to transform the
# Go through each httpd\d+.conf file and parse it.  Compare the result
# with the precomputed answer.
for (my $i=0; $i<@conf_files; ++$i) {
  my $conf_file = $conf_files[$i];

  # Only test the include transformation on httpd05.conf.
  my $c;
  my $opts_ref;
  if ($conf_file eq 'httpd05.conf') {
    $opts_ref = {post_transform_path_sub => \&post_transform_path};
  } elsif ($conf_file eq 'httpd07.conf') {
    $opts_ref = {post_transform_path_sub => [\&post_transform_munge, 1, 2]};
  }
  if ($opts_ref) {
    $c = EmptySubclass->new($opts_ref);
  } else {
    $c = EmptySubclass->new;
  }
  isa_ok($c, 'EmptySubclass');

  # Set the undocumented variable that instructs parse_file to
  # continue processing configuration files even when filenames given
  # to the AccessConfig, Include and ResourceConfig directives are
  # missing.  This lets the test suite test the normal aspects of all
  # the directives without worrying about a missing file halting the
  # tests early.
  $c->{_include_file_ignore_missing_file} = 1;
  ok($c->parse_file($conf_file), "loaded '$conf_file'");
  delete $c->{_include_file_ignore_missing_file};

  # Check the number of LoadModule's in each configuration file.  This
  # array is indexed by the number of configuration file.
  my @load_modules = (0, 37, 0, 37, 18, 0, 1, 37);
  is($c->find_down_directive_names('LoadModule'),
     $load_modules[$i],
     "found $load_modules[$i] LoadModule's in the whole file");

  # Check that the search for siblings of a particular node works.
  # Since some LoadModule's are inside <IfDefine> contexts, then this
  # will not find all of the LoadModules.
  @load_modules = (0, 26, 0, 26, 18, 0, 1, 26);
  is($c->find_siblings_directive_names('LoadModule'),
     $load_modules[$i],
     "found $load_modules[$i] LoadModule's at the top level");

  # This does a similar search but providing the start node.
  is($c->find_siblings_directive_names(($c->root->daughters)[-1],
                                       'LoadModule'),
     $load_modules[$i],
     "found $load_modules[$i] LoadModule's one level down");

  # Data::Dumper does not sort the hash keys so different versions of
  # Perl generate the same object but different Data::Dumper::Dumper
  # outputs.  To work around this, recursively descend into the object
  # and print the output ourselves.  Also, the errstr object variable
  # will sometimes be set and contain operating system specific error
  # messages which will not compare identically with the error
  # messages in the answer files, so modify them by removing the
  # operating system specific part.
  $c->{errstr} =~ s/:[^:]*$/: operating system specific error message/;
  my @result = $c->dump($c);

  # Read the answer file.
  my $answer_file =  $conf_file;
  $answer_file    =~ s/\.conf$/\.answer/;

  my $open_file = open(ANSWER, $answer_file);
  ok($open_file, "opened `$answer_file' for reading");
 SKIP: {
    skip "Cannot open $answer_file: $!", 1 unless $open_file;
    my @answer = <ANSWER>;
    @answer    = map { $_ =~ s/\r?\n$//; $_ } @answer;
    close(ANSWER);

    my $ok = eq_array(\@answer, \@result);
    ok($ok, "internal structure is ok");

    unless ($ok) {
      if (open(ANSWER, ">$answer_file.tmp")) {
        print ANSWER join("\n", @result), "\n";
        close(ANSWER);
      }
    }
  }
}
