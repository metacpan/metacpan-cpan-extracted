# small override of TAP::Parser::_initialize to extract args from testfiles

package t::tap;
use strict;
use base qw(TAP::Parser);
use File::Basename qw(fileparse);
use File::Spec;

sub new {
  my $class=shift;
  my($arg_for)=@_;
  my($source,$test_args)=@$arg_for{qw(source test_args)};
  my($script_plus_args,$dir)=fileparse($source);
  my($script,@args)=split(/\s+/,$script_plus_args);
  my $source=File::Spec->catfile($dir,$script);
  @args=grep {length $_} ($test_args,@args);
  @$arg_for{qw(source test_args)}=($source,\@args);
  $class->SUPER::new(@_);
}


# sub _initialize {
#     my $self=shift;
#     my($arg_for)=@_;
#     my($source,$test_args)=@$arg_for{qw(source test_args)};
#     my($script_plus_args,$dir)=fileparse($source);
#     my($script,@args)=split(/\s+/,$script_plus_args);
#     my $source=File::Spec->catfile($dir,$script);
#     @args=grep {length $_} ($test_args,@args);
#     @$arg_for{qw(source test_args)}=($source,\@args);
#     $self->SUPER::_initialize(@_);
# }
1;
