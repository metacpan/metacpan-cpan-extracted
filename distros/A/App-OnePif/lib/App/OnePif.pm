package App::OnePif;
use strict;
use warnings;
{ our $VERSION = '0.002'; }
use English qw( -no_match_vars );
use Carp;
use 5.010;

use Mo qw< is default >;
use Path::Tiny;
use YAML::Tiny;

{
   no warnings 'redefine';
   my @booleans = (
      'JSON::PP::Boolean',
      'JSON::XS::Boolean',
      'Types::Serialiser::Boolean',  # should not be needed
      'Mojo::JSON::_Bool',           # only up to Mojolicious 6.21
      # Dancer, Dancer2 use JSON
   );
   sub YAML::Tiny::dumper_for_unknown {
      my ($self, $element, $line, $indent, $seen) = @_;
      my $type = ref $element;

      for my $boolean (@booleans) {
         next unless $element->isa($boolean);
         $line .= $element ? ' true' : ' false';
         return $line;
      }

      # no known boolean... complain!
      die \"YAML::Tiny does not support $type references";
   }
}

has file => (
   is      => 'rw',
   lazy    => 1,
   default => sub { 'data.1pif' },
);

has attachments_dir => (
   is => 'rw',
   lazy => 1,
   default => sub {
      my $self = shift;
      path($self->file())->sibling('attachments')
   },
);

has records_byid => (
   is => 'rw',
   lazy => 1,
   default => sub {
      my $self = shift;
      my $bt = $self->records_bytype;
      my %retval;
      for my $list (values %$bt) {
         $retval{$_->{_id}} = $_ for @$list;
      }
      return \%retval;
   },
);

has records_bytype => (
   is => 'rw',
   lazy => 1,
   default => \&DEFAULT_records,
);

has JSON_decoder => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      for my $module (qw< JSON JSON::PP >) {
         (my $filename = "$module.pm") =~ s{::}{/}gmxs;
         my $retval = eval {
            require $filename;
            $module->can('decode_json');
         } or next;
         return $retval;
      } ## end for my $module (qw< JSON JSON::PP >)
      return;
   },
);

has YAML_dumper => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      for my $module (qw< YAML YAML::Tiny >) {
         (my $filename = "$module.pm") =~ s{::}{/}gmxs;
         my $retval = eval {
            require $filename;
            $module->can('Dump');
         } or next;
         return $retval;
      } ## end for my $module (qw< YAML YAML::Tiny >)
      return;
   },
);

has term => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      return Term::ReadLine->new('1password');
   },
);

has out => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      my ($self) = @_;
      my $term = $self->term();
      my $out = eval { $term->out() } || \*STDOUT;
      binmode $out, ':encoding(utf8)';
      return $out;
   },
);

has type => (
   is      => 'rw',
   lazy    => 1,
   default => sub { '*' },
);

has types => (
   is => 'rw',
   lazy => 1,
   default => \&DEFAULT_types,
);

sub run {
   my ($package, @ARGV) = @_;
   $package->new(args => \@ARGV)->run_interactive();
}

sub run_interactive {
   my ($self) = @_;
   my %main_for = (
      '.q' => 'quit',
      e => 'exit',
      f => 'file',
      h => 'help',
      l => 'list',
      p => 'print',
      q => 'quit',
      s => 'search',
      t => 'type',
      ts => 'types',
      u => 'type',
      use => 'type',
   );
   require Term::ReadLine;
   my $term = $self->term();
   my $out  = $self->out();
   $self->records_bytype; # just load...
   while (defined(my $line = $term->readline('1password> '))) {
      my ($command, $rest) = $line =~ m{\A \s* (\S+) \s* (.*?) \s*\z}mxs;
      next unless defined($command) && length($command);
      $command = $main_for{$command} if exists $main_for{$command};
      if (my $cb = $self->can("do_$command")) {
         $self->$cb($rest);
      }
      else {
         print {$out} "ERROR: unknown command [$command]\n",;
      }
   } ## end while (defined(my $line =...
} ## end sub run_interactive

sub attachments_for {
   my ($self, $uuid) = @_;
   my $target = $self->attachments_dir()->child($uuid);
   return unless $target->exists;
   return [ map { $_->stringify } $target->children ];
}

sub clear_records {
   my ($self) = @_;
   delete $self->{records_bytype};
   delete $self->{records_byid};
   delete $self->{types};
   $self->{type} = '*';
   return $self;
}

sub do_help {
   my ($self) = @_;
   $self->print(<<'END_OF_HELP');
Available commands:
* quit (also: q, .q)
   exit the program immediately, exit code is 0
* exit [code] (also: e)
   exit the program immediately, can accept optional exit code
* file [filename] (also: f)
   set the filename to use for taking data (default: 'data1.pif')
* types (also: ts)
   show available types and possible aliases
* type [wanted] (also: t, use, u)
   get current default type or set it to wanted. It is possible to
   reset the default type by setting type "*" (no quotes)
* list [type] (also: l)
   get a list for the current set type. By default no type is set
   and the list includes all elements, otherwise it is filtered
   by the wanted type.
   If type parameter is provided, work on specified type instead
   of default one.
* print [ <id> ] (also: p)
   show record by provided id (look for ids with the list command).
   It is also possible to specify the type, in which case the id
   is interpreted in the context of the specific type.
* search <query-string> (also: s)
   search for the query-string, literally. Looks for a substring in
   the YAML rendition of each record that is equal to the query-string,
   case-insensitively. If a type is set, the search is restricted to
   that type.
END_OF_HELP
}

sub do_quit {
   exit 0;
}

sub do_exit {
   my ($self, $code) = @_;
   exit($code || 0);
}

sub do_file {
   my ($self, $filename) = @_;
   if (defined $filename && length $filename) {
      if ($filename =~ m{\A(['"])(.*)$1\z}mxs) {
         $filename = $2;
      }
      $self->file($filename);
      $self->clear_records();
   } ## end if (defined $filename ...
   else {
      $self->print($self->file());
   }
   return $self;
} ## end sub do_file

sub DEFAULT_types {
   my $self = shift;

   state $aliases_for = {
      'passwords.Password' => [qw< p password passwords >],
      'securenotes.SecureNote' => [qw< note notes >],
      'wallet.computer.License' => [qw< license licenses >],
      'webforms.WebForm' => [qw< form forms >],
      'wallet.financial.CreditCard' => [qw< card cards >],
   };

   my $rbt = $self->records_bytype;
   my %retval = ('*' => ['*', '*']);
   for my $type (keys %$rbt) {
      my @alternatives = ($type, sort {
         (length($a) <=> length($b)) || ($a cmp $b)
      } @{$aliases_for->{$type} // []});
      push @alternatives, $type;
      $retval{$_} = \@alternatives for @alternatives;
   }

   # now first item is always the canonical form, second is the shortest
   # alias, then the rest including the canonical form at the end
   return \%retval;
}

sub do_types {
   my ($self) = @_;

   # might cache this somewhere...
   my %shorts;
   my $length = 0;
   for my $list (values %{$self->types}) {
      my ($canon, $shorter, @rest) = @$list;
      $shorts{$shorter} = \@rest;
      $length = length($shorter) if length($shorter) > $length;
   }
   $shorts{'*'} = ' (accept any type)';

   my $current = $self->type;
   my $marker = '<*>';
   my $blanks = ' ' x length $marker;
   for my $type (sort(keys %shorts)) {
      my $rest = $shorts{$type};
      $rest = " (also: @$rest)" if ref($rest) && @$rest;
      $rest = '' if ref $rest;
      my $indicator = $type eq $current ? $marker : $blanks;
      $self->print(sprintf "%s %${length}s%s", $indicator, $type, $rest);
   }
}

sub real_type {
   my ($self, $type) = @_;
   return '*' unless defined $type;
   my $types = $self->types;
   return unless exists $types->{$type};
   return $types->{$type}[0];
}

sub do_type {
   my ($self, $type) = @_;
   if (defined $type && length $type) {
      if ($self->real_type($type)) {
         $self->type($type);
      }
      else {
         $self->print("unknown type [$type]");
      }
   }
   else {
      $self->print($self->type());
   }
} ## end sub do_type

sub print {
   my $self = shift;
   print {$self->out()} @_, "\n";
}

sub DEFAULT_records {
   my ($self) = @_;
   my $file = $self->file();
   open my $fh, '<:raw', $file
      or croak "open('$file'): $OS_ERROR";
   my $decoder = $self->JSON_decoder;
   my %by_type;
   while (<$fh>) {
      my $record = $decoder->($_);
      if (my $attachments = $self->attachments_for($record->{uuid})) {
         $record->{attachments} = $attachments;
      }
      push @{$by_type{$record->{typeName}}}, $record;
      scalar <$fh>;    # drop a line
   }

   for my $list (values %by_type) {
      @$list = sort { $a->{title} cmp $b->{title} } @$list;
   }

   my $dumper  = $self->YAML_dumper;
   _traverse(\%by_type, undef, sub {
      my ($n, $v) = @_;
      $v->{_id} = $n;
      $v->{_yaml} = $dumper->($v);
   });

   return \%by_type;
}

sub do_list {
   my ($self, $type) = @_;
   $type ||= $self->type();
   $type = $self->real_type($type);
   my $records = $self->clipped_records_bytype($type);
   _traverse($records, sub {
      my ($key) = @_;
      $self->print($key) if $type eq '*';
   }, sub {
      my ($n, $record) = @_;
      $self->print(sprintf('   %3d %s', $record->{_id}, $record->{title}));
   });
}

sub do_print {
   my ($self, $id) = @_;
   my $by_id = $self->records_byid;
   if ($id && exists($by_id->{$id})) {
      $self->print($by_id->{$id}{_yaml});
   }
   else {
      $self->print('invalid id');
   }
}

sub do_search {
   my ($self, $query) = @_;
   $query = '' unless defined $query;
   $query =~ s{\A\s+|\s+\z}{}gmxs;
   return $self->do_list unless length $query;

   $query = quotemeta $query; # ready for a regex now
   my $type = $self->real_type($self->type);
   my $records = $self->clipped_records_bytype($type);
   my $last_printed_type = $type;
   _traverse($records, undef, sub {
         my ($n, $record) = @_;
         if ($record->{_yaml} =~ m{$query}i) {
            my $rt = $self->real_type($record->{typeName});
            if ($last_printed_type ne $rt) {
               $self->print($record->{typeName});
               $last_printed_type = $rt;
            }
            $self->print(sprintf('   %3d %s', $record->{_id},
                  $record->{title}));
         }
      });
}

sub clipped_records_bytype {
   my ($self, $type) = @_;
   $type = $self->real_type($type);
   my $records = $self->records_bytype();
   $records = { $type => $records->{$type} }
      unless $type eq '*';
   return $records;
}

sub _traverse {
   my ($hash, $key_callback, $values_callback) = @_;
   my $n = 0;
   for my $key (sort keys %$hash) {
      $key_callback->($key) if $key_callback;
      next unless $values_callback;
      $values_callback->(++$n, $_) for @{$hash->{$key}};
   }
}

1;
