package Bot::ChatBots::Utils;
use strict;
use warnings;
{ our $VERSION = '0.008'; }

use 5.010;
use Exporter 'import';
use Module::Runtime qw< use_module >;
use Ouch;

our @EXPORT_OK = qw< load_module pipeline resolve_module >;

sub load_module { return use_module(resolve_module(@_)) }

sub pipeline {
   return $_[0] if (@_ == 1) && (ref($_[0]) eq 'CODE');

   state $loaded = eval "use Data::Tubes '0.735002'; 1"
     or ouch 500, 'need Data::Tubes at least 0.736 for pipeline()';

   my %opts;
   %opts = %{shift(@_)} if (@_ && ref($_[0]) eq 'HASH');
   %opts = %{pop(@_)}   if (@_ && ref($_[-1]) eq 'HASH');
   $opts{prefix} //= 'Bot::ChatBots';
   $opts{tap} //= sub { ($_[0]->())[0] }
     unless exists $opts{pump};

   return Data::Tubes::pipeline(@_, \%opts);
} ## end sub pipeline

sub resolve_module {
   my ($name, $prefix) = @_;
   $prefix //= 'Bot::ChatBots';
   return substr($name, 1) if $name =~ m{\A[+^]}mxs;
   $name =~ s{^(::)?}{::}mxs;    # ensure separating "::" in front of $name
   return $prefix . $name;
} ## end sub resolve_module

42;
