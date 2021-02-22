package Command::Template::Instance;
use 5.024000;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '0.001' }

use Storable 'dclone';

# accessors
sub defaults ($self, @new) {
   return dclone($self->{defaults}) unless @new;
   $self->{defaults} = $new[0];
   return $self;
}
sub template ($self) { dclone($self->{template}) }

sub generate ($self, %bindings) {;
   my $defaults = $self->defaults;
   my @command;
   for my $arg ($self->template->@*) {
      if (! ref $arg) {
         push @command, $arg;
         next;
      }

      my ($name, $default, $type) = @{$arg}{qw< name default type >};
      my $value =
           exists $bindings{$name}   ? $bindings{$name}
         : exists $defaults->{$name} ? $defaults->{$name}
         : defined $default          ? $default
         :                             undef;
      if (defined $value) {
         push @command, ref($value) eq 'ARRAY' ? (@$value) : $value;
         next;
      }
      die "missing required parameter '$name'\n" if $type eq 'req';
   }
   return wantarray ? @command : \@command;
} ## end sub expand

sub new ($package, @input_command) {
   my @command;
   for my $arg (@input_command) {
      die "invalid parameter: undefined\n" unless defined $arg;
      die "invalid parameter: plain scalars only\n" if ref $arg;

      if (length($arg) == 0) {
         push @command, '';
         next;
      }

      my $first_char = substr $arg, 0, 1;
      if ($first_char eq '\\') {
         push @command, substr $arg, 1;
         next;
      }
      elsif ($first_char ne '<' && $first_char ne '[') {
         push @command, $arg;
         next;
      }

      my ($type, $lc) = $first_char eq '<' ? ('req', '>') : ('opt', ']');
      my ($name, $default) = $arg =~ m{
         \A \Q$first_char\E
            ([a-zA-Z_]\w+)  # name, starts with no digit
            (?: = (.*))?   # optional default value
         \Q$lc\E \z
      }mxs or die "invalid parameter {$arg}\n";
      push @command,
        {
         default => $default,
         name    => $name,
         type    => $type,
        };
   } ## end for my $arg (@_)

   return bless { defaults => {}, template => \@command }, $package;
} ## end sub _parse_command

1;
