package IO::All::Base;

# use Mo qw'default build import exporter xxx';
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.38
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=&{$M.Object::new}($c,@_);my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};*{$M.'exporter::e'}=sub{my($P)=@_;if(@{$M.EXPORT}){*{$P.$_}=\&{$M.$_}for@{$M.EXPORT}}};use constant XXX_skip=>1;my$dm='YAML::XS';*{$M.'xxx::e'}=sub{my($P,$e)=@_;$e->{WWW}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::WWW(@_)};$e->{XXX}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::XXX(@_)};$e->{YYY}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::YYY(@_)};$e->{ZZZ}=sub{require XXX;local$XXX::DumpModule=$dm}};@f=qw[default build import exporter xxx];use strict;use warnings;

our @EXPORT = qw(chain option);

sub option {
    my $package = caller;
    my ($field, $default) = @_;
    $default ||= 0;
    field("_$field", $default);
    no strict 'refs';
    *{"${package}::$field"} =
      sub {
          my $self = shift;
          $self->{"_$field"} = @_ ? shift(@_) : 1;
          return $self;
      };
}

sub chain {
    my $package = caller;
    my ($field, $default) = @_;
    no strict 'refs';
    *{"${package}::$field"} =
      sub {
          my $self = shift;
          if (@_) {
              $self->{$field} = shift;
              return $self;
          }
          return $default unless exists $self->{$field};
          return $self->{$field};
      };
}

sub field {
    my $package = caller;
    my ($field, $default) = @_;
    no strict 'refs';
    return if defined &{"${package}::$field"};
    *{"${package}::$field"} =
      sub {
          my $self = shift;
          unless (exists $self->{$field}) {
              $self->{$field} =
                ref($default) eq 'ARRAY' ? [] :
                ref($default) eq 'HASH' ? {} :
                $default;
          }
          return $self->{$field} unless @_;
          $self->{$field} = shift;
      };
}

package IO::All::OO::Object;

sub throw {
    my $self = shift;
    require Carp;
    Carp::croak(@_);
}

1;
