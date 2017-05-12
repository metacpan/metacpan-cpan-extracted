package Simple;
use strict;
use warnings;

use Class::XPath
  get_name => 'name',
  get_parent => 'parent',
  get_root   => 'root',
  get_children => 'kids',               
  get_attr_names => 'param',
  get_attr_value => 'param',
  get_content    => 'data';


sub name   { shift->{name} }
sub parent { shift->{parent} }
sub root   { local $_=shift; 
             while($_->{parent}) { $_ = $_->{parent} }
             return $_; }
sub param { if (@_ == 2) { return $_[0]->{$_[1]} } 
            else { return qw(foo bar baz) } }
sub data { shift->{data} }
sub kids { @{shift->{kids}} }

sub new_root { my $pkg = shift; bless({kids => [], @_}, $pkg); }
sub add_kid { my $self = shift; 
              push(@{$self->{kids}}, 
                  bless({kids => [], @_, parent => $self }, ref $self));
              $self->{kids}[-1]; }
                 
1;
