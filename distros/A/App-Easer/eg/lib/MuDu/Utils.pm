package MuDu::Utils;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Path::Tiny 'path';
use Exporter 'import';

our @EXPORT = qw< add_file autospec edit_file fatal get_title list_category
   move_task notice path resolve >;

sub add_file ($config, $hint, $contents) {
   my $attempts = 0;
   my $file     = path($hint);
   while ('necessary') {
      eval {
         my $fh =
           $file->filehandle({exclusive => 1}, '>', ':encoding(UTF-8)');
         print {$fh} $contents;
         close $fh;
      } && return $file;
      ++$attempts;
      last if $config->{attempts} && $attempts >= $config->{attempts};
      $file = $hint->sibling($hint->basename . "-$attempts");
   } ## end while ('necessary')
   fatal("cannot save file '$hint' or variants");
} ## end sub add_file

sub autospec ($package, %direct) {
   for my $key (qw< description help options supports >) {
      next if exists $direct{$key};
      my $sub = $package->can($key) or next;
      $direct{$key} = $sub->();
   }
   $direct{execute} //= $package;
   return \%direct;
}

sub edit_file ($config, $path) {
   my $editor = $config->{editor};
   my $outcome = system {$editor} $editor, $path->stringify;
   return $outcome == 0;
}

sub fatal ($message) { die join(' ', @_) . "\n" }

sub get_title ($path) {
   my ($title) = $path->lines({count => 1});
   ($title // '') =~ s{\A\s+|\s+\z}{}grmxs;
}

sub list_category ($config, $category) {
   my $dir = path($config->{basedir})->child($category);
   return reverse sort { $a cmp $b } $dir->children;
}

sub move_task ($config, $src, $category) {
   $src = $src->[0] if 'ARRAY' eq ref $src;
   my $child = resolve($config, $src);
   my $parent = $child->parent;
   if ($parent->basename eq $category) {
      notice("task is already $category");
      return 0;
   }
   my $dest = $parent->sibling($category)->child($child->basename);
   add_file($config, $dest, $child->slurp_utf8);
   $child->remove;
   return 0;
} ## end sub move_task

sub notice ($message) { warn join(' ', @_) . "\n" }

# path comes from Path::Tiny

sub resolve ($config, $oid) {
   fatal("no identifier provided") unless defined $oid;
   my $id = $oid;

   my %name_for = (o => 'ongoing', d => 'done', w => 'waiting');
   my $first = substr $id, 0, 1, '';
   my $type = $name_for{$first} // fatal("invalid identifier '$oid'");

   my $child;
   if ($id =~ s{\A -}{}mxs) {    # exact id
      $child = path($config->{basedir})->child($type, $id);
      fatal("unknown identifier '$oid'") unless -r $child;
   }
   else {
      fatal("invalid identifier '$oid'")
        unless $id =~ m{\A [1-9]\d* \z}mxs;
      my @children = list_category($config, $type);
      fatal(
"invalid identifier '$oid' (too high, max $first@{[scalar @children]})"
      ) if $id > @children;
      $child = $children[$id - 1];
   } ## end else [ if ($id =~ s{\A -}{}mxs)]

   return $child;
} ## end sub resolve


1;
