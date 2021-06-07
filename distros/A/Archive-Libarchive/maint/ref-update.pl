#!/usr/bin/env perl

use strict;
use warnings;
use LibarchiveRef;
use File::chdir;
use FFI::Platypus 1.00;
use FFI::ExtractSymbols;
use Path::Tiny qw( path );
use Clang::CastXML;
use Const::Introspect::C;
#use YAML qw( Dump );
use List::Util 1.33 qw( all sum0 );
use PerlX::Maybe;
use Template;
use Pod::Abstract;
use 5.020;
use experimental qw( signatures );

my %optional;
my %manual;
my $ffi;
my $archive_h;
my $entry_h;
my %count = (
  manual     => 0,
  generated  => 0,
  incomplete => 0,
  removed    => 0,
);

my %removed;

{
  my %in_oldest;

  {
    my $version = ref_config->{OLDEST};
    local $CWD = "/opt/libarchive/$version/lib";
    my $so = "libarchive.so";
    $so = readlink $so if -l $so;
    say "# libarchive $version, so=$so";

    extract_symbols($so,
      code => sub ($symbol, $) {
        return unless $symbol =~ /^archive_/;
        $in_oldest{$symbol} = 1;
      },
    );
  }

  {
    my $version = ref_config->{LATEST};
    local $CWD = "/opt/libarchive/$version/lib";
    my $so = "libarchive.so";
    $so = readlink $so if -l $so;
    say "# libarchive $version, so=$so";

    extract_symbols($so,
      code => sub ($symbol, $) {
        return unless $symbol =~ /^archive_/;
        return if $in_oldest{$symbol};
        $optional{$symbol} = 1;
      },
    );
  }

  {
    my $castxml = Clang::CastXML->new;

    $archive_h = $castxml->introspect( path('/usr/include/archive.h') )->to_href;
    $entry_h   = $castxml->introspect( path('/usr/include/archive_entry.h') )->to_href;
  }

  {
    my $original = \&FFI::Platypus::DL::dlsym;
    no warnings 'redefine';
    local *FFI::Platypus::DL::dlsym = sub ($handle, $symbol) {
      $manual{$symbol} = 1;
      return $original->($handle, $symbol);
    };
    no warnings 'once';
    $Archive::Libarchive::no_gen = 1;
    require Archive::Libarchive;
  }

  $count{manual} = scalar keys %manual;
  $ffi = Archive::Libarchive::Lib->ffi;
}

my $tt = Template->new({
  INCLUDE_PATH => [path(__FILE__)->parent->child('tt')->stringify],
  FILTERS => {
    type => sub ($name) {
      $name ne '' ? "'$name'" : 'undef';
    },
  },
});

my @const;

{
  my $c = Const::Introspect::C->new(
    headers => ['archive.h','archive_entry.h'],
  );

  foreach my $const ($c->get_macro_constants)
  {
    next unless $const->name =~ /^ARCHIVE_/;
    next if $const->name eq 'ARCHIVE_VERSION_NUMBER';
    next if $const->name =~ /^ARCHIVE_COMPRESSION_/;
    next unless $const->type eq 'int';
    push @const, $const;
  }

  my $path = 'lib/Archive/Libarchive/Lib/Constants.pm';

  @const = sort { $a->name cmp $b->name } @const;

  my %enums;

  my @const2 = map {
    my $c = $_;
    $c->name =~ /^ARCHIVE_(FILTER|FORMAT|ENTRY_DIGEST)_(.*)$/ ? do {
      $enums{$1}->{name}   //= "archive_@{[ lc $1 ]}_t";
      $enums{$1}->{prefix} //= "ARCHIVE_$1_";
      push $enums{$1}->{constants}->@*, {
        name  => lc($2),
        value => $c->value,
      };
      ();
    } : $_;
  } @const;

  $tt->process('Const.pm.tt', {
    class     => 'Constants',
    constants => \@const2,
    enums     => [sort { $a->{name} cmp $b->{name} } values %enums],
  }, $path) or do {
    say "Error generating $path @{[ $tt->error ]}";
    exit 2;
  };

}

{
  my %bindings;
  my %functions;
  process_functions($archive_h, \%functions, \%bindings);
  process_functions($entry_h,   \%functions, \%bindings);
  generate(\%functions, \%bindings);
}

sub type_fixup ($type)
{
  if(defined $type && $type =~ /^(archive|archive_entry|archive_entry_linkresolver)(\*+)$/)
  {
    return $2 eq '*' ? $1 : undef;
  }
  else
  {
    return $type;
  }
}

sub process_functions ($href, $global, $bindings)
{
  my %id;

  my $get_type = sub ($name, $id)
  {
    my $type = $id{$id};
    return $type->{platypus_type} if defined $type->{platypus_type};

    if($type->{_class} =~ /^(FundamentalType|Typedef|Struct)$/)
    {
      my $ctype = $type->{name};
      $ctype = 'long' if $ctype eq 'long int';
      $ctype = 'sint64' if $ctype eq 'la_int64_t';
      $ctype = 'ulong' if $ctype eq 'long unsigned int';
      $ctype = 'uint' if $ctype eq 'unsigned int';
      $ctype = 'ssize_t' if $ctype eq 'la_ssize_t';
      if(eval { $ffi->type($ctype) })
      {
        return $type->{platypus_type} = $ctype;
      }
    }

    if($type->{_class} =~  /^(CvQualifiedType|ElaboratedType)$/ )
    {
      return $type->{platypus_type} = __SUB__->($name, $type->{type});
    }

    if($type->{_class} eq 'PointerType')
    {
      my $target_type = __SUB__->($name, $type->{type});
      if(defined $target_type)
      {
        if($target_type eq 'char')
        {
          return $type->{platypus_type} = 'string';
        }
        elsif($target_type eq 'wchar_t')
        {
          return $type->{platypus_type} = 'wstring'
        }
        elsif($target_type eq 'void')
        {
          return $type->{platypus_type} = 'opaque'
        }
        elsif($target_type =~ /^(archive|archive_entry|archive_entry_linkresolver)$/)
        {
          return $type->{platypus_type} = "$target_type*";
        }
        elsif($target_type =~ /^(int|string|size_t|ssize_t|ulong|uint|sint64)$/)
        {
          return $type->{platypus_type} = "$target_type*";
        }
      }

      $type->{target_type} = $target_type;
    }

    #say "unhandled type:";
    #say Dump({ $name => $type });
    return undef;
  };

  foreach my $item ($href->{inner}->@*)
  {
    $id{$item->{id}} = $item if exists $item->{id} && defined $item->{id};
  }

  my %functions;

  foreach my $f (grep { $_->{_class} eq 'Function' && $_->{name} =~ /^archive_/ } $href->{inner}->@*)
  {
    $functions{$f->{name}} = $f;
  }

  {
    my @prune;

    foreach my $name (keys %functions)
    {
      # if there is a _utf8 variant we don't really want
      # to muck with the wchar_t variant since Perl uses UTF-8 internally.
      if($name =~ /^(.*)_utf8$/)
      {
        push @prune, "${1}_w";
      }

      # Some methods need to be implemented manually with
      # wrappers or if they have unusual name changes,
      # so we remove them here.
      push @prune, $name if $manual{$name};

      # From the header file:
      # Return an opaque ACL object.
      # There's not yet anything clients can actually do with this...
      push @prune, $name if $name eq 'archive_entry_acl';

      # we use the newer next_header2 method
      push @prune, $name if $name eq 'archive_read_next_header';

      # This ... doesn't really work or make sense for Perl the
      # way it is implemented.
      push @prune, $name if $name eq 'archive_write_open_memory';

      # From the header file:
      # A more involved version that is only used for internal testing.
      push @prune, $name if $name eq 'archive_read_open_memory2';

      # We don't call this version, since it wasn't in 3.0.2 and
      # it is a shortcut for archive_*_free functions.
      push @prune, $name if $name eq 'archive_free';

      # these are aliases that are being renamed in 3.x and removed in 4.x
      push @prune, $name if $name =~ /^archive_(write_set_compression.*|read_support_compression.*|position_(compressed|uncompressed)|compression(_name|)|(read|write)_open_file|entry_acl_text(|_w))$/;

      # The _finish forms were renamed to _Free in 3.x and will be
      # removed in 4.x
      push @prune, $name if $name =~ /^archive_(read|write)_finish$/;

      # utility function to sort strings.  Don't really need this
      # in perl
      push @prune, $name if $name eq 'archive_utility_string_sort';

      # Since callbacks are closures we don't really need to worry about
      # client data.  Not 100% sure this is what I think it is so
      # we maybe should revisit later.
      push @prune, $name if $name =~ /^archive_read_(add_callback_data|append_callback_data|prepend_callback_data|set_callback_data2)$/;

      # The open and open2 archive read methods are permutations of setting callbacks and calling open1
      # that we don't really need.
      push @prune, $name if $name =~ /^archive_read_open2?$/l
    }

    foreach my $name (@prune)
    {
      if(delete $functions{$name})
      {
        $count{removed}++;
        $removed{$name}++ unless $manual{$name};
      }
    }
  }

  foreach my $name (sort keys %functions)
  {
    my $f = $functions{$name};
    my $ret_type = type_fixup($get_type->($name, $f->{returns}));
    my @arg_types = map { type_fixup($get_type->($name, $_->{type} )) } $f->{inner}->@*;

    my $class;
    my $orig = $name;
    my $opt = $optional{$orig} ? 1 : undef;
    my $perl_name;

    if(defined $arg_types[0])
    {
      if($arg_types[0] eq 'archive_entry' && $name =~ /^archive_entry_(.*)$/)
      {
        $class = 'Entry';
        $name = $1;
        $ret_type = 'void' if $name eq 'clear';
      }

      if($arg_types[0] eq 'archive_entry_linkresolver' && $name =~ /^archive_entry_linkresolver_(.*)$/)
      {
        $class = 'EntryLinkResolver';
        $name = $1;
      }

      if($arg_types[0] eq 'archive')
      {
        if($name =~ /^archive_write_(disk_.*)$/)
        {
          $arg_types[0] = 'archive_write_disk';
          $class = 'DiskWrite';
          $name = $1;
        }

        elsif($name =~ /^archive_read_(disk_.*)$/)
        {
          $arg_types[0] = 'archive_read_disk';
          $class = 'DiskRead';
          $name = $1;
        }

        elsif($name =~ /^archive_read_(.*)$/)
        {
          $arg_types[0] = 'archive_read';
          $class = 'ArchiveRead';
          $name = $1;
          $perl_name = "read_$1" if $name =~ /^(data|data_skip|data_block|data_into_fd)$/;
        }

        elsif($name =~ /^archive_write_(.*)$/)
        {
          $arg_types[0] = 'archive_write';
          $class = 'ArchiveWrite';
          $name = $1;
          $perl_name = "write_$1" if $name =~ /^(data|header|data_block)$/;
        }

        elsif($name =~ /^archive_match_(.*)$/)
        {
          $arg_types[0] = 'archive_match';
          $class = 'Match';
          $name = $1;
        }

        elsif($name =~ /^archive_(.*)$/)
        {
          $class = 'Archive';
          $name = $1;
        }

      }
    }

    if($name =~ /^(.*)_utf8$/)
    {
      $ret_type = 'string_utf8' if $ret_type eq 'string';
    }

    $class //= "Unbound";

    say "warning: $orig returns $ret_type (check ownership)" if $ret_type =~ /^archive/;

    my $incomplete = (defined $ret_type && all { defined $_ } @arg_types) ? undef : 1;
    $count{$incomplete ? 'incomplete' : 'generated'}++;

    say "warning: $orig is incomplete" if $incomplete;

    push $bindings->{$class}->@*, {
            symbol_name => $orig,
      maybe optional    => $opt,
            name        => $name,
      maybe perl_name   => $perl_name,
            arg_types   => \@arg_types,
            ret_type    => $ret_type,
      maybe incomplete  => $incomplete,
    };
  }

  %$global = (%$global, %functions);
}

sub munge_types (@types)
{
  my @munged;

  state $varnames = {
    archive                    => 'ar',
    archive_read               => 'r',
    archive_write              => 'w',
    archive_read_disk          => 'dr',
    archive_write_disk         => 'dw',
    archive_match              => 'm',
    archive_entry              => 'e',
    archive_entry_linkresolver => 'lr',
  };

  splice @types, 1, 1;

  @types = map { $varnames->{$_} // $_ } @types;

  my %count;
  $count{$_}++ for @types;
  %count = map { $count{$_} > 1 ? ($_ => 1) : () } keys %count;

  foreach my $type (@types)
  {
    if($count{$type})
    {
      if($type =~ /\d$/a)
      {
        $type .= "_" . $count{$type}++;
      }
      else
      {
        $type .= $count{$type}++;
      }
    }

    $type = "\$$type";
    if($type =~ /^(.*)\*$/)
    {
      $type = "\\$1";
    }
    push @munged, $type;
  }

  my $ret_type = shift @munged;
  return (ret_type => $ret_type, arg_types => \@munged);
}

sub man_made_methods ($class=undef)
{
  my $pa = Pod::Abstract->load_file(defined $class ? "lib/Archive/Libarchive/$class.pm" : 'lib/Archive/Libarchive.pm');

  $_->detach for $pa->select('//#cut');

  map {
    my %h = (
      name => $_->param('heading')->pod,
      pod  => $_->pod,
    );
    \%h;
  } $pa->select(q{/head1[@heading =~ {METHODS|CONSTRUCTOR|FUNCTIONS}]/head2});
}

sub generate ($function, $bindings)
{
  foreach my $class (sort keys %$bindings)
  {
    my $docname;
    my $path = path(qw( lib Archive Libarchive Lib ), do {
      my @name = split /::/, $class;
      $docname = $name[-1];
      $name[-1] .= ".pm";
      @name
    });
    $path->parent->mkpath;
    $tt->process('Code.pm.tt', {
      class => $class,
      bindings => {
        required => [grep { !$_->{optional} } $bindings->{$class}->@*],
        optional => [grep { $_->{optional} } $bindings->{$class}->@*],
      },
      docname => "Lib::$docname",
    }, "$path") or do {
      say "Error generating $path @{[ $tt->error ]}";
      exit 2;
    };
  }

  state $varnames = {
    Archive           => 'ar',
    ArchiveRead       => 'r',
    ArchiveWrite      => 'w',
    DiskRead          => 'dr',
    DiskWrite         => 'dw',
    Entry             => 'e',
    Match             => 'm',
    EntryLinkResolver => 'lr',
  };

  my @classes = map {
    my %h = (
      name => $_,
      var  => $varnames->{$_} // do { say "set a varname for $_"; exit 2 },
      methods => [
        sort { $a->{name} cmp $b->{name} }
        (man_made_methods($_),
         map { { %$_, name => $_->{perl_name} // $_->{name}, munge_types($_->{ret_type}, $_->{arg_types}->@*) } }
         grep { ! $_->{incomplete} }
         $bindings->{$_}->@*)
      ],
      parent => do {
        no strict 'refs';
        ${"Archive::Libarchive::${_}::ISA"}[0];
      },
    );
    \%h;
  } sort grep { $_ ne 'Unbound' } keys %$bindings;

  unshift @classes, {
    name => undef,
    methods => [
      sort { $a->{name} cmp $b->{name} } man_made_methods()
    ],
  };

  foreach my $binding ($bindings->{'Unbound'}->@*)
  {
    $removed{$binding->{name}} = 1;
  }

  my $path = 'lib/Archive/Libarchive/API.pm';
  $tt->process('Doc.pm.tt', {
    classes   => \@classes,
    removed   => [sort keys %removed],
    docname   => 'API',
    constants => \@const,
  }, $path) or do {
    say "Error generating $path @{[ $tt->error ]}";
    exit 2;
  };

  foreach my $pm (sort grep { $_->basename =~ /\.pm$/ } (path('lib/Archive/Libarchive.pm'), path('lib/Archive/Libarchive')->children))
  {
    next if $pm->basename eq 'API.pm';
    my $tmp;
    my($content) = split /__END__/, $pm->slurp_utf8;
    my $docname = $pm->basename =~ s/\.pm$//r;
    $tt->process('SeeAlso.pm.tt', {
      content => $content,
      docname => $docname,
    }, "$pm") or do {
      say "Error updating $path @{[ $tt->error ]}";
    };
  }
}

foreach my $key (sort keys %count)
{
  printf "%10s | %3s\n", $key, $count{$key};
}
printf "%10s | %3s\n", 'total', sum0 values %count;
