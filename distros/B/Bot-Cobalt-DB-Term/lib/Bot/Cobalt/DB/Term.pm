package Bot::Cobalt::DB::Term;
our $VERSION = '0.001';

### FIXME: POD is out of date and not well-ordered

use 5.12.1;
use strict;
use warnings;
use Carp;

use Bot::Cobalt::DB;
use Bot::Cobalt::Serializer;

use Data::Dumper;

use File::Spec;

use Term::UI;
use Term::ReadLine;

use Text::ParseWords qw/parse_line/;

sub new {
  my $self = {};
  my $class = shift;
  bless $self, $class;
  
  $self->{RL}  = Term::ReadLine->new('cobalt2-dbterm');
  $self->{OUT} = $self->{RL}->OUT || \*STDOUT;
  
  my %args = @_;
  if (defined $args{Open}) {
    $self->{INITIAL_PATH} = $args{Open};
  }
  
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  if ($self->{CURRENT} && $self->{CURRENT}->is_open) {
    warn "Closing DB due to DESTROY";
    $self->{CURRENT}->dbclose;
  }
}

sub _switch_db {
  my ($self, $dbpath) = @_;
  my $o = $self->{OUT};
  unless (-f $dbpath) {
    print $o "Path $dbpath is not a normal file.\n",
             "Perhaps you wanted to `create`?\n",
    return
  }
  
  my $db = Bot::Cobalt::DB->new(
    File => $dbpath,
    Raw  => 1,
  );
  
  unless ( $db->dbopen ) {
    print $o "Could not open DB at $dbpath.\n";
    return
  }
  my $count = $db->dbkeys;
  print $o "Opened database $dbpath\n",
           "Database has $count keys.\n";
  
  $db->dbclose;
  
  $self->{CURRENT} = $db;
  
  return 1
}

sub _get_current {
  my ($self) = @_;
  return unless $self->{CURRENT};
  return $self->{CURRENT}
}

sub interactive {
  my ($self) = @_;
  $self->{RUN} = 1;
  my $o = $self->{OUT};
  my $t = $self->{RL};
  
  if (defined $self->{INITIAL_PATH}) {
    my $path = $self->{INITIAL_PATH};
    unless ( $self->_switch_db($path) ) {
      print $o "Could not open initial DB at $path\n";
      return
    }
  }
  
  PROMPT: while ($self->{RUN}) {
    my $db = $self->{CURRENT};
    my $dbstatus;
    if ( $db and ref $db and $db->can('File') ) {
      $dbstatus = (File::Spec->splitpath($db->File))[2];
    } else {
      $dbstatus = 'no db selected';
    }
    my $cmd = $t->get_reply(
      prompt => "($dbstatus) dbterm> ",
      default => 'help',
    );
  
    if ($cmd) {
      $t->addhistory($cmd);
      my ($thiscmd, @args) = parse_line('\s+', 0, $cmd);
      next PROMPT unless $thiscmd;
      unless ( lc($thiscmd) ~~ 
        [ qw/h help q quit open create freeze thaw/ ]
      ) {
        unless ( $self->_get_current ) {
          print $o "No database currently open; try `help` or `open`\n";
          next PROMPT
        }
      }
      
      my $thismethod = '_cmd_'.$thiscmd;
      if ($self->can($thismethod)) {
        $self->$thismethod(@args);
      } else {
        print $o "Unknown command, try `help`\n";
        next PROMPT
      }
    }
    
  } ## PROMPT
}


sub _cmd_h { _cmd_help(@_) }
sub _cmd_help {
  my ($self, $item) = @_;
  my $o = $self->{OUT};

  my $help = {
    open => [
      "open <path>",
      " Attempts to open the specified Bot::Cobalt::DB.",
    ],

    copy => [
      "copy <srckey> <destkey>",
      " Copies a value from key <srckey> to <destkey>.",
      " Overwrites any existing destination key.",
    ],
 
    create => [
      "create <path>",
      " Creates a new database at the specified path.",
    ],

    current => [
      "current",
      " Display path to currently-selected DB",
      " (Same as `size`)",
    ],

    del => [
      "del <key>",
      " Deletes the specified key.",
    ],

    freeze => [
      "freeze <perl data>",
      " Displays serialized Perl data structures.",
      " A format can optionally be specified:",
      "  freeze --yaml { Some => 'Hash' }",
    ],
      
    get => [
      "get <key>",
      " Retrieves the specified key.",
    ],
    
    getref => [
      "getref <key>",
      " Retrieves and deserializes the specified key.",
    ],
 
    grep => [
      "grep <regex>",
      " Search all DB values for the specified regex.",
      " (May lock the DB for a long time on a large DB!)",
    ],
 
    keys => [
      "keys [regex]",
      " Lists all keys in DB.",
      " Optionally allows searching keys by regex.",
    ],

    put => [
      "put <key> <data>",
      " Inserts raw data as the value of the specified key.",
      " Note that <data> is usually JSON.",
    ],
 
    putref => [
      "putref <key> <perl data>",
      " Inserts a serialized Perl data structure.",
      " Example: putref mykey { Str => 'things', Bool => 1 }",
    ],
     
    thaw => [
      "thaw <serialized>",
      " Displays Perl data structures thawed from frozen references.",
    ],
  };

  if (!$item || !defined $help->{$item}) {
    my $cmds = join ' ', sort keys %$help;
    print $o (join "\n", 
      "Commands: ",
      "$cmds\n",
      "Use `help <cmd>` for cmd usage information.\n",
    );
    return
  }
  
  my $thishelp = join "\n", @{ $help->{$item} };
  print $o $thishelp, "\n";
}

sub _cmd_q    { _cmd_quit(@_) }
sub _cmd_quit {
  my ($self) = @_;
  my $o = $self->{OUT};
  print $o "Exiting.\n";
  $self->{RUN} = 0;
}

sub _cmd_open {
  my ($self, $path) = @_;
  my $t = $self->{RL};
  my $o = $self->{OUT};
  
  if ($self->{CURRENT}) {
    print $o "Switching from open DB\n";
    $self->{CURRENT}->dbclose if $self->{CURRENT}->is_open;
  }
  
  until (defined $path) {
    $path = $t->get_reply(
      prompt => 'Path to database: ',
    );
  }
  
  unless ( $self->_switch_db($path) ) {
    print $o "Could not switch to DB at $path\n";
    return
  }
}

sub _cmd_size   { _cmd_current(@_) }
sub _cmd_sizeof { _cmd_current(@_) }
sub _cmd_current {
  my ($self) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};
  
  my $current = $db->File;
  print $o "Current DB: $current\n";
  my $size = -s $current;
  $size = sprintf("%.02f", $size / 1024);
  print $o "Size: $size kbytes\n";
}

sub _cmd_copy {
  my ($self, $key, $dest) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};
  
  unless (defined $key && defined $dest) {
    print $o "Usage: copy <key> <dest>\n";
    return
  }
  
  unless ( $db->dbopen ) {
    print $o "Database open failure\n";
    return
  }
  
  my $item = $db->get($key);
  
  unless (defined $item) {
    print $o "No value defined for $key\n";
    $db->dbclose;
    return
  }
  
  if ( $db->get($dest) ) {
    print $o "!! Overwriting destination key $dest\n";
  }

  $db->put($dest, $item);  
  $db->dbclose;
  require bytes;
  my $datalen = bytes::length($item);
  print $o "Copied $datalen bytes from $key to $dest\n";
}

sub _cmd_fetch { _cmd_get(@_) }
sub _cmd_get {
  my ($self, $key) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};
  
  unless (defined $key) {
    print $o "Usage: get <key>\n";
    return
  }
  
  unless ( $db->dbopen(ro => 1) ) {
    print $o "Database open failure\n";
    return
  }
  
  my $item = $db->get($key);
  $db->dbclose;  
  
  unless (defined $item) {
    print $o "No value defined for $key\n";
    return
  }

  print $item ."\n";
}

sub _cmd_getref {
  my ($self, $key) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};
  
  unless (defined $key) {
    print $o "Usage: getref <key>\n";
    return
  }

  my $ser = Bot::Cobalt::Serializer->new('JSON');

  unless ( $db->dbopen(ro => 1) ) {
    print $o "Database open failure\n";
    return
  }
  
  my $item = $db->get($key);
  $db->dbclose;  
  
  unless (defined $item) {
    print $o "No value defined for $key\n";
    return
  }
  
  my $ref;
  eval { $ref = $ser->thaw($item) };
  if ($@) {
    print $o "Could not thaw value; maybe not JSON?\n";
    return
  }
  
  unless (ref $ref) {
    print $o "Thawed value not a reference\n";
    return
  }
  
  print $o Dumper $ref;  
}

sub _cmd_putref {
  my ($self, $key, @data) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};

  unless (defined $key && @data) {
    print $o "Usage: putref <key> <data ..>\n";
    return
  }
  
  my $datastr = join ' ', @data;
  my $ref;
  $ref = eval $datastr;
  unless ($ref && ref $ref) {
    print $o "Could not putref; input not a reference.\n";
    return
  }

  my $ser = Bot::Cobalt::Serializer->new('JSON');
  my $serialized;
  eval { $serialized = $ser->freeze($ref) };
  if ($@) {
    print $o "Could not serialize reference.\n";
    return
  }

  unless ( $db->dbopen ) {
    print $o "Database open failure.\n";
    return
  }
  $db->put($key, $serialized);
  $db->dbclose;
  
  require bytes;
  my $datalen = bytes::length($serialized);
  print $o "Added $datalen bytes to $key\n";
}

sub _cmd_set { _cmd_put(@_) }
sub _cmd_put {
  my ($self, $key, @data) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};

  unless (defined $key && @data) {
    print $o "Usage: put <key> <data ..>\n";
    return
  }

  unless ( $db->dbopen ) {
    print $o "Database open failure.\n";
    return
  }
  
  my $datastr = join ' ', @data;
  $db->put($key, $datastr);
  require bytes;
  my $datalen = bytes::length($datastr);
  print $o "Added $datalen bytes to $key\n";
  my $retrieved = $db->get($key);
  unless ($retrieved eq $datastr) {
    print $o "Warning; Re-retrieved item doesn't match original put()\n";
  }
  $db->dbclose;

}

sub _cmd_delete { _cmd_del(@_) }
sub _cmd_del {
  my ($self, $key) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};

  unless (defined $key) {
    print $o "Usage: del <key>\n";
    return
  }

  unless ( $db->dbopen ) {
    print $o "Database open failure.\n";
    return
  }
  
  unless ( defined $db->get($key) ) {
    print $o "Key $key doesn't appear to exist.\n";
    $db->dbclose;
    return
  }
  
  unless ( $db->del($key) ) {
    print $o "del() returned false for key $key\n";
  } else {
    print $o "Deleted key $key\n";
  }
  
  $db->dbclose;
  
}

sub _cmd_list { _cmd_keys(@_) }
sub _cmd_ls   { _cmd_keys(@_) }
sub _cmd_keys {
  my ($self, $str) = @_;
  my $db = $self->{CURRENT};
  my $o  = $self->{OUT};

  unless ( $db->dbopen(ro => 1) ) {
    print $o "Database open failure.\n";
    return
  }

  my @keys = $db->dbkeys;
  
  unless (@keys) {
    print $o "Empty database.\n";
    $db->dbclose;
    return
  }
  
  if ($str) {
    my $re = qr/$str/;
    my @discard = @keys;
    @keys = ();
    for my $thiskey (@discard) {
      push(@keys, $thiskey)
        if $thiskey =~ $re;
    }
    print $o "No matching keys found." unless @keys;
  }
  print $o '('.scalar @keys.' keys)' if @keys;  
  print $o join "\n", sort @keys, "\n";
  $db->dbclose;
}

sub _cmd_create {
  my ($self, $dbpath) = @_;
  my $o = $self->{OUT};
  my $t = $self->{RL};

  unless ($dbpath) {
    print $o "Usage: create <path>\n";
    return
  }
  
  if (-e $dbpath) {
    my $rpl = $t->ask_yn(
      prompt => "Should I overwrite the existing file?",
      default => 'n',
      print_me => "That path already exists.",
    );
    
    unless ($rpl) {
      print $o "Skipping; path exists.\n";
      return
    } else {
      if (-f $dbpath) {
        unlink($dbpath);
      } else {
        print $o "Skipping; cannot unlink; not a regular file: $dbpath\n";
        return
      }
    }
  }

  my $db = Bot::Cobalt::DB->new(
    File => $dbpath,
    Raw  => 1,
  );
  
  unless ( $db->dbopen ) {
    print $o "Could not open DB at $dbpath.\n";
    return
  }
  ## test our db real quick
  my $tstr = 'test scalar'.rand(666);
  $db->put('test', $tstr);
  my $test = $db->get('test');
  unless ($test eq $tstr) {
    print $o "Warning; new DB failed to return consistent value\n";
  }
  $db->del('test');
  $db->dbclose;
  
  unless ( $self->_switch_db($dbpath) ) {
    print $o "Could not switch to DB at $dbpath\n";
    return
  }
  
  print $o "Created and switched to new DB\n";
  print $o "Path: $dbpath\n";
}

sub _cmd_freeze {
  my ($self, @args) = @_;
  my $o = $self->{OUT};
  my $t = $self->{RL};
  
  my $format = 'JSON';
  if ( index($args[0], '--') == 0 ) {
    my $f_opt = shift @args;
    substr($f_opt, 0, 2, '');
    given (lc($f_opt//'')) {
      $format = 'YAMLXS' when "yaml";
      $format = 'YAML'   when "syck";
      $format = 'XML'    when "xml";
      default { print $o "Unknown type: $f_opt\n" ; return }
    }
  }
  
  my $str = join ' ', @args;
  
  my $ref;
  $ref = eval $str;
  unless ($ref and ref $ref) {
    print $o "Could not putref; input not a reference.\n";
    return
  }
  
 
  my $ser = Bot::Cobalt::Serializer->new($format);
  my $serialized;
  eval { $serialized = $ser->freeze($ref) };
  if ($@) {
    print $o "Serializer could not freeze reference\n";
    return
  }
  
  print $o $serialized;
}

sub _cmd_thaw {
  my ($self, @args) = @_;
  my $o = $self->{OUT};
  my $t = $self->{RL};

  my $format = 'JSON';
  if ( index($args[0], '--') == 0 ) {
    my $f_opt = shift @args;
    substr($f_opt, 0, 2, '');
    given (lc($f_opt//'')) {
      $format = 'YAMLXS' when "yaml";
      $format = 'YAML'   when "syck";
      $format = 'XML'    when "xml";
      default { print $o "Unknown type: $f_opt\n" ; return }
    }
  }
  
  my $str = join ' ', @args;
  my $ser = Bot::Cobalt::Serializer->new($format);
  my $ref;
  eval { $ref = $ser->thaw($str) };
  if ($@) {
    print $o "Serializer could not thaw string\n";
    return
  }
  
  print $o Dumper $ref;  
}

sub _cmd_grep {
  my ($self, $regex) = @_;
  my $o  = $self->{OUT};
  my $db = $self->{CURRENT};
  
  unless ($regex) {
    print $o "Usage: grep <regex>\n";
    return
  }
  
  $regex = qr/$regex/;
    
  unless ( $db->dbopen(ro => 1) ) {
    print $o "Database open failure.\n";
    return
  }

  my @result;

  KEY: for my $key ($db->dbkeys) {
    my $data = $db->get($key) // next KEY;
    push(@result, $key) if $data =~ $regex;
  }
  
  $db->dbclose;
  
  unless (@result) {
    print $o "No results.\n";
    return
  }
  
  print $o $_."\n" for sort @result;
  my $count = scalar @result;
  print $o "($count results found)\n";
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::DB::Term - Bot::Cobalt::DB terminal interface

=head1 SYNOPSIS

  $ cobalt2-dbterm
  
  ## Or via Perl:
  Bot::Cobalt::DB::Term->new->interactive;

=head1 DESCRIPTION

A simple L<Term::UI>-based interface allowing interaction with 
L<Bot::Cobalt::DB> databases.

Also allows interaction with L<Bot::Cobalt::Serializer> via 
L</thaw> and L</freeze>.

(For complete functionality you'll probably want L<Term::ReadLine::Gnu>, 
or at least L<Term::ReadLine::Perl>.)

=head1 COMMANDS

Command arguments can be quoted.

=head2 help

Retrieve command line help.

=head2 quit

Exit.

=head2 open

Open a specified database.

Required prior to specifying commands.

The database is opened to make sure it is valid, then 
unlocked again.

All other operations take place against whatever database was 
last opened via C<open>.

=head2 create

Create and open a new database at the specified location.

=head2 current

Display the path to the currently-selected database.

=head2 keys

List or search database keys.

If no arguments are specified, the entire list of keys will 
be returned.

A regular expression can be specified as an argument.

=head2 get

Get the raw value for a specified key.

=head2 getref

Display the deserialiazed reference for a specified key.

L<Bot::Cobalt::DB> databases usually store values as serialized 
references; C<getref> will use L<Data::Dumper> to display the 
data structure that would be created by deserializing.

=head2 put

  put KEY DATA ...

Add raw data to the specified key.

(You can, of course, horribly break your database this way, if you like.)

=head2 putref

  putref KEY PERLDATA ...
  
Add a serialized reference to the specified key.

For example:

  putref MyKey { Some => 'Hash', Array => [ ] }
  putref MyArr [ 'A', 'B', 'C' ]

=head2 del

Deletes the specified key.

=head2 freeze

Freezes a Perl data structure via L<Bot::Cobalt::Serializer>.

For example:

  freeze { Some => 'Hash' }

Defaults to JSON.
A Bot::Cobalt::Serializer format can optionally be specified:

  freeze --yaml { Some => 'Hash' }
  freeze --xml  { Some => 'Hash' }

=head2 thaw

Thaws a serialized data structure and displays it via L<Data::Dumper>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
