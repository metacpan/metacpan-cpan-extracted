#!/usr/bin/perl
#
# Copyright  (c)  2015-2017  T.v.Dein <tlinden  |AT|  cpan.org>.   All
# Rights Reserved. Std. disclaimer applies.  Artistic License, same as
# perl itself. Have fun.
#


package Data::Interactive::Inspect;

use Carp::Heavy;
use Carp;

use Term::ReadLine;
use File::Temp qw(tempfile); # required by the 'edit' command
use YAML;                    # config + export/import + 'edit' command

use strict;
use warnings;
no strict 'refs';

use Data::Dumper;

$Data::Interactive::Inspect::VERSION = 0.07;

use vars qw(@ISA);

use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();


sub new {
  my ($class, @param) = @_;

  $class = ref($class) || $class;

  # defaults (= valid parameters)
  my $self = {
              name        => '',
              begin       => sub { print STDERR "unsupported\n"; },
              commit      => sub { print STDERR "unsupported\n"; },
              rollback    => sub { print STDERR "unsupported\n"; },
              export      => sub { my ($db) = @_; return $db; },
              serialize   => sub { my $db = shift; return YAML::Dump($db); },
              deserialize => sub { my $db = shift; return YAML::Load($db); },
              struct      => {},
              editor      => 'vi',
              more        => 'more',
              silent      => 0,
             };

  bless $self, $class;

  # by default unsupported
  $self->{transactions} = 0;

  if ($#param >= 1) {
    # hash interface
    my %p = @param;
    foreach my $k (keys %{$self}) {
      if (exists $p{$k}) {
        $self->{$k} = $p{$k};
      }
    }
    if (exists $p{begin} && $p{commit} && $p{rollback}) {
      # user supplied the relevant functions
      $self->{transactions} = 1;
    }
  }
  elsif ($#param == 0) {
    # 1 param, the struct
    $self->{struct} = $param[0];
  }
  # else: no params given, work with defaults

  if (! $self->{struct}) {
    croak "Sorry param 'struct' must be set to a perl data structure\n";
  }

  # map commands+shortcuts to functions
  $self->{command} = {
                      l     => 'list',
                      list  => 'list',
                      show  => 'show',
                      sh    => 'show',
                      dump  => 'dump',
                      d     => 'dump',
                      get   => 'get',
                      g     => 'get',
                      enter => 'enter',
                      cd    => 'enter',
                      set   => 'set',
                      edit  => 'edit',
                      e     => 'edit',
                      append=> 'append',
                      drop  => 'drop',
                      pop   => 'mypop',
                      shift => 'myshift',
                      search=> 'search',
                      '/'   => 'search',
                      help  => 'help',
                      h     => 'help',
                      '?'   => 'help',
                      quit  => 'quit',
                      q     => 'quit',
                     };

  if ($self->{transactions}) {
    # map if supported
    foreach my $c (qw(begin commit rollback)) {
      $self->{command}->{$c} = $c;
    }
  }

  if (! $self->{name}) {
    $self->{name} = sprintf "data\@0x%x", $self->{struct};
  }

  # map which commands take a key param
  $self->{commandargs} = [qw(get set edit show append pop shift drop enter cd search /)];

  # holds current level
  $self->{db} = $self->{struct};

  # path to current level
  $self->{path} = [];

  # set to 1 if transactions supported and implemented
  $self->{session} = 0;

  $self->{quit} = 0;

  return $self;
}




sub inspect {
  my ($self, $__cmds) = @_;

  if ($__cmds) {
    # unit tests und scripts
    $self->{silent} = 1;
    foreach (split /\n/, $__cmds) {
      if (! $self->process($_, 1) ) {
        last;
      }
    }
    return $self->{struct};
  }

  if (-t STDIN) {
    # interactive with prompt and history
    $| = 1;
    my $term = new Term::ReadLine 'Data::Interactive::Inspect';
    $term->ornaments(0);
    my $attribs = $term->Attribs;

    $self->{term} = $term;
    $self->{complete_words} = [ map { if (length($_) > 2 ) {$_} } keys %{$self->{command}} ];
    $attribs->{completion_entry_function} = $attribs->{list_completion_function}; # avoid file completion
    $attribs->{attempted_completion_function} = sub {
      my ($begin, $line, $start, $end, $term) = @_;
      return $self->complete($begin, $line, $start, $end, $term);
    };

    my $prompt = $self->prompt;
    while ( defined ($_ = $term->readline($prompt)) ) {
      if (! $self->process($_) ) {
        print "last\n";
        last;
      }
      $prompt = $self->prompt;
    }
  }
  else {
    while (<STDIN>) {
      if (! $self->process($_, 1) ) {
        last;
      }
    }
  }
  return $self->{struct};
}

sub prompt {
  my $self = shift;
  my $prompt = $self->{name};

  if (@{$self->{path}}) {
    $prompt .= " " . join('->', @{$self->{path}});
  }
  if ($self->{session}) {
    $prompt .= '%';
  }
  $prompt .= '> ';
  return $prompt;
}

sub complete {
  my ($self, $begin, $line, $start, $end, $term) = @_;

  my @matches = ();

  my $cmd = $line;
  $cmd =~ s/\s\s*.*$//;
  $cmd =~ s/\s*$//;

  if ($start == 0) {
    # match on a command
    @matches = $self->{term}->completion_matches ($begin, sub {
                                                    my ($text, $state) = @_;
                                                    my @name = @{$self->{complete_words}};
                                                    unless ($state) {
                                                      $self->{complete_idx} = 0;
                                                    }
                                                    while ($self->{complete_idx} <= $#name) {
                                                      $self->{complete_idx}++;
                                                      return $name[$self->{complete_idx} - 1]
                                                        if ($name[$self->{complete_idx} - 1] =~ /^$text/);
                                                    }
                                                    # no match
                                                    return undef;
                                                  });
  }
  elsif ($line =~ /[^\s]+\s+[^\s]+\s+/) {
    # command line is complete ($cmd $arg), stop with completion
    @matches = undef;
  }
  else {
    # match on a command arg
    if (grep {$cmd eq $_} @{$self->{commandargs}}) {
      # only match for commands which support args
      @matches = $self->{term}->completion_matches ($begin, sub {
                                                      my ($text, $state) = @_;
                                                      my @name = keys %{$self->{db}};
                                                      unless ($state) {
                                                        $self->{complete_idxp} = 0;
                                                      }
                                                      while ($self->{complete_idxp} <= $#name) {
                                                        $self->{complete_idxp}++;
                                                        return $name[$self->{complete_idxp} - 1]
                                                          if ($name[$self->{complete_idxp} - 1] =~ /^$text/);
                                                      }
                                                      # no match
                                                      return undef;
                                                    });
    }
    else {
      # command doesn't support args
      @matches = undef;
    }
  }

  return @matches;
}

sub process {
  my ($self, $line, $failonerr) = @_;

  return 1 if(!defined $line);

  # special treatment to search command
  $line =~ s|^/(.+)|/ $1|;

  my $r;
  my ($cmd, @args) = split /\s\s*/, $line;

  return 1 if (!defined $cmd);
  return 1 if ($cmd =~ /^\s*$/);
  return 1 if ($cmd =~ /^#/);



  if ($cmd eq '..') {
    $self->up;
  }
  else {
    if (exists $self->{command}->{$cmd}) {
      my $func = $self->{command}->{$cmd};
      if (! grep {$cmd eq $_} @{$self->{commandargs}}) {
        @args = ();
      }
      $r = $self->$func(@args);
      return 0 if($failonerr && !$r); # fail if not interactive
      return 0 if($self->{quit});     # finish
    }
    else {
      if (ref($self->{db}) =~ /hash/i) {
        if (exists $self->{db}->{$cmd}) {
          $r = $self->enter($cmd);
          return 0 if($failonerr && !$r); # fail if not interactive
        }
        else {
          print STDERR "no such command: $cmd\n";
          return 0 if $failonerr;
        }
      }
      else {
        print STDERR "no such command: $cmd\n";
        return 0 if $failonerr;
      }
    }
  }
  return 1;
}



# command implementations
sub __interactive__ {};

sub _fail {
  my ($self, $msg) = @_;
  print STDERR $msg;
  return 0;
}

sub _failkey {
  my $self = shift;
  return $self->_fail("<key> parameter missing\n");
}

sub _failidx {
  my $self = shift;
  return $self->_fail("<key> must be a number, since we're inside an array\n");
}

sub _more {
  my ($self, $out) = @_;
  if (open LESS, "|$self->{more}") {
    print LESS $out;
    close LESS;
  }
  else {
    print $out;
  }
}

sub quit {
  my $self = shift;
  $self->{quit} = 1;
  return 0;
}

sub set {
  my($self, $key, @value) = @_;

  return $self->_failkey() if(! defined $key);

  my $var;
  my $code = "\$var = @value;";
  {
    no strict;
    no warnings;
    eval $code;
  }
  if ($@) {
    return $self->_fail("failed to insert: $@\n");
  }
  else {
    $self->{db}->{$key} = $var;
    $self->done;
  }
  return 1;
}

sub append {
  my($self, $key, @value) = @_;

  if (ref($self->{db}) !~ /array/i) {
    return $self->_failkey() if(! defined $key);

    if (exists $self->{db}->{$key}) {
      if (ref($self->{db}->{$key}) !~ /array/i) {
        return $self->_fail("\"$key\" already exists and is not an array\n");
      }
    }
  }
  else {
    # inside an array, ignore $key
    @value = ($key, @value);
  }

  my $var;
  my $code = "\$var = @value;";
  eval $code;
  if ($@) {
    return $self->_fail("failed to evaluate: $@\n");
  }
  else {
    if (ref($self->{db}) =~ /array/i) {
      push @{$self->{db}}, $var;
    }
    else {
      push @{$self->{db}->{$key}}, $var;
    }
    $self->done;
  }

  return 1;
}

sub drop {
  my($self, $key) = @_;

  if (ref($self->{db}) =~ /array/i) {
    return $self->_failidx if($key !~ /^\d*$/);
    if (scalar @{$self->{db}} -1 < $key) {
      return $self->_fail("array element $key exceeds number of elements in current array\n");
    }
    else {
      splice @{$self->{db}}, $key, 1;
      $self->done;
    }
  }
  else {
    return $self->_failkey() if(! defined $key);

    if (exists $self->{db}->{$key}) {
      delete $self->{db}->{$key};
      $self->done;
    }
    else {
      return $self->_fail("no such key: \"$key\"\n");
    }
  }

  return 1;
}

sub mypop {
  my($self, $key) = @_;

  if (ref($self->{db}) !~ /array/i) {
    return $self->_failkey() if(! defined $key);

    if (exists $self->{db}->{$key}) {
      if (ref($self->{db}->{$key}) !~ /array/i) {
        return $self->_fail("\"$key\" is not an array\n");
      }
    }
    my $ignore = pop @{$self->{db}->{$key}};
    $self->done;
  }
  else {
    my $ignore = pop @{$self->{db}};
  }

  return 1;
}

sub myshift {
  my($self, $key) = @_;

  if (ref($self->{db}) !~ /array/i) {
    return $self->_failkey() if(! defined $key);

    if (exists $self->{db}->{$key}) {
      if (ref($self->{db}->{$key}) !~ /array/i) {
        return $self->_fail("\"$key\" is not an array\n");
      }
    }
    my $ignore = shift @{$self->{db}->{$key}};
    $self->done;
  }
  else {
    my $ignore = shift @{$self->{db}};
  }
  return 1;
}

sub get {
  my($self, $key, $search) = @_;

  return $self->_failkey() if(! defined $key);

  my $out;
  my @K;
  if ($key =~ /^\/.*\/$/) {
    # regex
    $key =~ s#^/##;
    $key =~ s#/$##;
    foreach my $k (keys %{$self->{db}}) {
      if ($k =~ /$key/) {
        push @K, $k;
      }
    }
  }
  else {
    if (ref($self->{db}) =~ /array/i) {
      return $self->_failidx if($key !~ /^\d*$/);
      if (scalar @{$self->{db}} -1 < $key) {
        return $self->_fail("array element $key exceeds number of elements in current array\n");
      }
      else {
        $out .= "[$key] =>\n" . $self->dump($self->{db}->[$key], 1)
      }
    }
    elsif (exists $self->{db}->{$key}) {
      push @K, $key;
    }
    else {
      return $self->_fail("no such key: \"$key\"\n");
    }
  }

  foreach my $key (@K) {
    if (ref($self->{db}->{$key}) =~ /hash/i || ref($self->{db}->{$key}) =~ /array/i) {
      # FIXME: something nicer
      $out .= "$key =>\n" . $self->dump($self->{db}->{$key}, 1)
    }
    else {
      $out .= "$key => \"$self->{db}->{$key}\"\n";
    }
  }
  print $out;

  return 1;
}

sub dump {
  my ($self, $obj, $noprint) = @_;
  my $out;
  if ($obj) {
    $out = $self->{serialize}->($self->{export}->($obj));
  }
  else {
    $out = $self->{serialize}->($self->{export}->($self->{db}));
  }

  if ($noprint) {
    return $out;
  }
  else {
    $self->_more($out);
  }

  return 1;
}

sub edit {
  my ($self, $key) = @_;

  return $self->_failkey() if(! defined $key);

  if (exists $self->{db}->{$key}) {
    my $data = $self->{serialize}->($self->{export}->($self->{db}->{$key}));
    my ($fh, $filename) = tempfile();
    print $fh $data;
    close $fh;
    system("$self->{editor}", $filename);
    open IN, "<$filename";
    my $newdata = join '', <IN>;
    close IN;
    if ($newdata eq $data) {
      # FIXME: use checksum or something else which is faster
      print "unchanged\n";
    }
    else {
      my $perl;
      eval {
        $perl = $self->{deserialize}->($newdata);
      };
      if ($@) {
        return $self->_fail("$@\n");
      }
      else {
        $self->{db}->{$key} = $perl;
        $self->done;
      }
    }
    unlink($filename);
  }
  else {
    return $self->_fail("no such key: \"$key\"\n");
  }

  return 1;
}

sub list {
  my $self = shift;

  if (ref($self->{db}) eq 'ARRAY') {
    # already implements array listing
    $self->show;
  }
  else {
    my $out = join("\n", sort keys %{$self->{db}}) . "\n";
    $self->_more($out);
  }

  return 1;
}

sub show {
  my ($self, $indent) = @_;
  my $out;

  if (ref($self->{db}) =~ /array/i) {
    my $pos = 0;
    foreach my $item (@{$self->{db}}) {
      $out .= "$pos:\n";
      if (ref($item)) {
        $out .= $self->_showhash($item, "    ");
      }
      else {
        $out .= "   $item\n";
      }
      $pos++;
    }
  }
  else {
    $out = $self->_showhash($self->{db});
  }

  $self->_more($out);

  return 1;
}

sub _showhash {
  my($self, $db, $indent) = @_;

  if (!defined $indent) {
    $indent = '';
  }

  my $out;
  foreach my $key (sort keys %{$db}) {
    $out .= sprintf "%s%-30s", $indent, $key;
    if (ref($db->{$key}) =~ /hash/i) {
      $out .= "{ .. }\n";
    }
    elsif (ref($db->{$key}) =~ /array/i) {
      $out .= "[ .. ]\n";
    }
    else {
      $out .= "\"$db->{$key}\"\n";
    }
  }

  return $out;
}

sub enter {
  my ($self, $key) = @_;

  return $self->_failkey() if(! defined $key);

  if ($key eq '..') {
    $self->up;
  }
  else {
    if (ref($self->{db}) =~ /array/i) {
      # "cd" into array element
      return $self->_failidx if($key !~ /^\d*$/);
      push @{$self->{path}}, "[${key}]";
      push @{$self->{prev}}, $self->{db};
      $self->{db} = $self->{db}->[$key];
    }
    elsif (ref($self->{db}->{$key}) =~ /hash/i || ref($self->{db}->{$key}) =~ /array/i) {
      # "cd" into the hash pointed at by $key
      push @{$self->{prev}}, $self->{db};
      push @{$self->{path}}, $key;
      $self->{db} = $self->{db}->{$key};
      print "=> $key\n";
    }
    else {
      return $self->_fail("not a hash: \"$key\"\n");
    }
  }

  return 1;
}

sub up {
  my $self = shift;
  if (@{$self->{prev}}) {
    $self->{db} = pop @{$self->{prev}};
    pop @{$self->{path}};
    print "<=\n";
  }
  else {
    return $self->_fail("already on top level\n");
  }

  return 1;
}

sub search {
  my ($self, $regex) = @_;

  if (! defined $regex) {
    $self->_fail("<regex> parameter missing\n");
  }

  $self->{spath} = [];

  return $self->_search($self->{db}, $regex);
}

sub _search {
  my($self, $db, $regex) = @_;

  if (ref($db) =~ /hash/i) {
    foreach my $key (sort keys %{$db}) {
      $self->_searchmatch($key, $regex, 0);
      push @{$self->{spath}}, $key;
      $self->_search($db->{$key}, $regex);
      pop @{$self->{spath}};
    }
  }
  elsif (ref($db) =~ /array/i) {
    my $pos = 0;
    foreach my $item (@{$db}) {
      push @{$self->{spath}}, "[${pos}]";
      $self->_search($item, $regex);
      pop @{$self->{spath}};
      $pos++;
    }
  }
  else {
    $self->_searchmatch($db, $regex, 1);
  }

  return 1;
}

sub _searchmatch {
  my ($self, $key, $regex, $quote) = @_;
  $quote = $quote ? '"' : '';
  if ($key =~ /$regex/) {
    print join(' => ', @{$self->{spath}}) . ": ${quote}$ {key}${quote}\n";
  }
}

sub done {
  my $self = shift;
  if (! $self->{silent}) {
    print "ok\n";
  }
}

sub help {
  my $self = shift;
  print qq(Display commands:
  list                  - list keys of current level
  show                  - same as list but with values
  dump                  - dump everything from current level
  get <key> | /regex/   - display value of <key>, or the value
                          of all keys matching /regex/
  search <regex>        - search for <regex>

Navigation commands:
  enter <key>           - change level into sub-hash of <key>

Edit commands:
  set <key> <value>     - set <key> to <value>
  edit <key>            - edit structure behind <key> [1]
  append [<key>] <value>- append <value> to array <key>, leave <key>
                          if you are currently inside an array
  drop <key>            - delete key <key>, use a number if inside
                          an array
  pop [<key>]           - remove last element of array <key>,
  shift [<key>]         - remove first element of array <key>
                          leave <key> if inside an array
);

  if ($self->{transactions}) {
    print qq(
Transaction commands:
  begin                 - start a transaction session
  commit                - store everything changed within session
  rollback              - discard changes
);
  }

  print qq(
Misc commands:
  help                  - get help
  ctrl-d | quit         - exit

Shortcuts:
  ..                    - go one level up
  l                     - list
  d                     - dump
  sh                    - show
  cd                    - enter
  <key>                 - enter <key> [2]
  /<regex>              - search <regex>

Hints:
[1] <value> can be perl code, e.g: set pw { user => 'max' }
[2] doesn't work if <key> correlates to a command
);
}


1;

=head1 NAME

Data::Interactive::Inspect - Inspect and manipulate perl data structures interactively

=head1 SYNOPSIS

 use Data::Interactive::Inspect;
 my $data = foo(); # get a hash ref from somewhere

 # new shell object, the simple way
 my $shell = Data::Interactive::Inspect->new($data);

 # or
 my $shell = Data::Interactive::Inspect->new(
   struct      => $data,
   name        => 'verkehrswege',
   begin       => sub { .. },
   commit      => sub { .. },
   rollback    => sub { .. },
   serialize   => sub { .. },
   deserialize => sub { .. },
   editor      => 'emacs',
   more        => 'less'
 );

 $data = $shell->inspect(); # opens a shell and returns modified hash ref on quit


=head1 DESCRIPTION

This module provides an interactive shell which can be used to inspect and modify
a perl data structure.

You can browse the structure like a directory, display the contents, add and remove
items, whatever you like. It is possible to include complete perl data structures.

The module works with hash and array references.

=head1 METHODS

=head2 new

The B<new()> function takes either one parameter (a reference to a hash or array)
or a hash reference with parameters. The following parameters are supported:

=over

=item B<struct>

The hash or array reference to inspect.

=item B<name>

Will be displayed on the prompt of the shell.

=item B<editor>

By default L<Data::Interactive::Inspect> opens B<vi> if the user issues the B<edit>
command. Use this parameter to instruct it otherwise.

=item B<more>

By default L<Data::Interactive::Inspect> uses B<more> to display data which doesn't
fit the terminal window. Use this parameter to instruct it otherwise.

=item B<begin>, B<commit>, B<rollback>

If your data is tied to some backend which supports transactions, you can provide
functions to implement this. If all three are defined, the user can use transaction
commands in the shell.

Look at L<DBM::Deep::Manager> for an example implementation.

=item B<serialize>, B<deserialize>

By default L<Data::Interactive::Inspect> uses L<YAML> for serialization, which
is used in the B<edit> and B<dump> commands. You can change this by assigning
code refs to these parameters.

B<serialize> will be called with the structure to be serialized as its sole
parameter and is expected to return a string.

B<deserialize> will be called with a string as parameter and is expected to
return a structure.

=back

=head2 inspect

The B<inspect> method starts the shell. Ii does return if the user leaves it, otherwise
it runs forever.

The shell runs on a terminal and with STDIN.

The interactive shell supports command line editing, history and completion (for
commands and hash keys), if L<Term::ReadLine::GNU> or L<Term::ReadLine::Perl> is
installed.

=head1 INTERACTIVE COMMANDS

=head2 DISPLAY COMMANDS

=over

=item B<list>

Lists the keys of the current level of the structure.

Shortcut: B<l>.

=item B<show>

Does nearly the same as B<list> but also shows the content of the
keys. If a key points to a structure (like a hash or an array), B<show>
whill not display anything of it, but instead indicate, that there'e
more behind that key.

For arrays the array indices are displayed as well.

Shortcut: B<sh>.

=item B<dump>

Dumps out everything of the current level of the structure.

Shortcut: B<d>.

=item B<get> key | /regex/>

Displays the value of B<key>. If you specify a regex, the values of
all matching keys will be shown.

If the current structure is an array you can specify the array index
as the parameter.

=item B<search> regex | /<regex>

Search for B<regex> through the current structure. Looks for
keys an values.

Beware that this make take some time depending on the size
of the structure.

=back

=head2 NAVIGATION COMMANDS

=over

=item B<enter> key

You can use this command to enter a sub hash of the current hash.
It works like browsing a directory structure. You can only enter
keys which point to sub hashes.

Shortcuts: B<cd>

If the key you want to enter doesn't collide with a command, then
you can also just directly enter the key without 'enter' or 'cd' in
front of it, eg:

 my.db> list
 subhash
 my.db> subhash
 my.db subhash> dump
 my.db subhash> ..
 my.db>^D

If the current structure is an array you can use the array index
to enter a specific array item.

If you specify B<..> as parameter (or as its own command like in the
example below), you go one level up and leave the current sub hash.

=back

=head2 EDIT COMMANDS

=over

=item B<set> key value

Use the B<set> command to add a new key or to modify the value
of a key. B<value> may be a valid perl structure, which you can
use to create sub hashes or arrays. Example:

 my.db> set users [ { name => 'max'}, { name => 'joe' } ]
 ok
 mydb> get users
 users =>
 {
   'name' => 'max'
 },
 {
   'name' => 'joe'
 }

B<Please note that the B<set> command overwrites existing values
without asking>.

=item B<edit> key

You can edit a whole structure pointed at by B<key> with the
B<edit> command. It opens an editor with the structure converted
to L<YAML>. Modify whatever you wish, save, and the structure will
be saved to the database.

=item B<append> key value

This command can be used to append a value to an array. As with the
B<set> command, B<value> can be any valid perl structure.

If you are currently inside an array, leave the B<key> parameter.

=item B<drop> key

Delete a key.

Again, note that all commands are executed without further asking
or warning!

If you are currently inside an array, the B<key> parameter must be
an array index.

=item B<pop> key

Remove the last element of the array pointed at by B<key>.

If you are currently inside an array, leave the B<key> parameter.

=item B<shift> key

Remove the first element of the array pointed at by B<key>.

If you are currently inside an array, leave the B<key> parameter.

=back

=head2 TRANSACTION COMMANDS

B<Only available if transaction support has been enabled, see below>.

=over

=item B<begin>

Start a transaction.

=item B<commit>

Save all changes made since the transaction began.

=item B<rollback>

Discard all changes of the transaction.

=back

=head2 MISC COMMANDS

=over

=item B<help>

Display a short command help.

Shortcuts: B<h> or B<?>.

=item B<CTRL-D>

Quit the interactive shell

Shortcuts: B<quit>.

=back

=head1 LIMITATIONS

The data structure you are inspecting with L<Data::Interactive::Inspect> may
contain code refs. That's not a problem as long as you don't touch them.

Sample:

 my $c = {
     opt => 'value',
     hook => sub { return 1; },
    };
 my $shell = Data::Interactive::Inspect->new($c);
 $shell->inspect();

Execute:

 data@0x80140a468> dump
 ---
 hook: !!perl/code '{ "DUMMY" }'
 opt: value
 data@0x80140a468> set hook blah
 data@0x80140a468> edit hook

Both commands would destroy the code ref. The first one would just overwrite it
while the other one would remove the code (in fact it remains a code ref but
it will contain dummy code only).

=head1 TODO

=over

=item Add some kind of select command

Example:

struct:

 {
   users => [
              { login => 'max', uid => 1 },
              { login => 'leo', uid => 2 },
            ]
 }

 > select login from users where uid = 1

which should return 'max'.

(may require a real world parser)

=item Add some kind of schema support

Given the same structure as above:

 > update users set uid = 4 where login = 'max'

=back

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 BUGS

Report bugs to
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data::Interactive::Inspect

=head1 COPYRIGHT

Copyright (c)  2015-2017 by  T.v.Dein <tlinden@cpan.org>.   All rights
reserved.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 VERSION

This is the manual page for L<Data::Interactive::Inspect> Version 0.07.

=cut
