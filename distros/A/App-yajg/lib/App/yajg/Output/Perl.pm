package App::yajg::Output::Perl;

use 5.014000;
use strict;
use warnings;
use utf8;

use parent qw(App::yajg::Output);

use App::yajg;
use Data::Dumper qw();

sub lang              {'perl'}    # lang for highlight
sub need_change_depth {0}         # need to change max depth via Data::Dumper

sub as_string {
    my $self = shift;
    local $SIG{__WARN__} = \&App::yajg::warn_without_line;
    no warnings 'redefine';
    local *Data::Dumper::qquote = $self->escapes
      ? \&Data::Dumper::qquote
      : sub {
        local $_ = shift;
        s/\\/\\\\/g;
        s/'/\\'/g;
        utf8::encode($_) if utf8::is_utf8($_);
        return "'$_'";
      };
    my $perl = eval {
        Data::Dumper->new([$self->data])
          ->Indent(int not $self->minimal)
          ->Pair($self->minimal ? '=>' : ' => ')
          ->Terse(1)
          ->Sortkeys($self->sort_keys // 0)
          ->Useperl(int not $self->escapes)
          ->Useqq(1)
          ->Deepcopy(1)
          ->Maxdepth($self->max_depth // 0)
          ->Dump()
    };
    if ($@) {
        warn $@;
        return '';
    }
    return $perl;
}

1;
