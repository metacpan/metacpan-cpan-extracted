package DBIx::Mojo::Template;
use Mojo::Base -base;
use Mojo::Loader qw(data_section);
use Mojo::Template;
use Mojo::URL;
use Mojo::Util qw(url_unescape);


#~ has debug => $ENV{DEBUG_DBIx_Mojo_Template} || 0;
#~ my $pkg = __PACKAGE__;

sub new {
  my ($class) = shift;
  bless $class->data(@_);
}

sub singleton {
  my ($class) = shift;
  state $singleton = bless {};
  my $data = $class->data(@_);
  @$singleton{ keys %$data } = values %$data;
  $singleton;
}

sub data {
  my ($class, $pkg, %arg) = @_;
  die "Package not defined!"
    unless $pkg;
  my $data = {};
  #~ weaken $data;
  while ( my ($k, $t) = each %{data_section $pkg})  {
    my $url = Mojo::URL->new($k);
    my ($name, $param) = (url_unescape($url->path), $url->query->to_hash);
    utf8::decode($name);
    $data->{$name} = DBIx::Mojo::Statement->new(dict=>$data, name=>$name, sql=>$t, param=>$param, mt=>_mt(%{$arg{mt} || {}}), vars=>$arg{vars} || {});
  }
  die "None DATA dict in package [$pkg]"
    unless %$data;
  return $data;
}

sub _mt {
  Mojo::Template->new(vars => 1, prepend=>'no strict qw(vars); no warnings qw(uninitialized);', @_);# line_start=>'$$',
}

sub template { shift->render(@_) }

sub render {
  my ($self, $key, %arg) = @_;
    die "No such item by key [$key] on this DICT, please check processed package"
        unless $self->{$key};
    $self->{$key}->render(%arg);
  
}

our $VERSION = '0.055';

#=============================================
package DBIx::Mojo::Statement;
#=============================================
use Mojo::Base -base;
use Hash::Merge qw(merge);
#~ use Scalar::Util 'weaken';

has [qw(dict name sql param mt vars sth)];
# sth - attr for save cached dbi statement

use overload '""' => sub { shift->sql };

sub template { shift->render(@_) }

sub render {
  my $self = shift;
  my $vars =ref $_[0] ? shift : { @_ };
  $vars->{dict} ||= $self->dict;
  #~ weaken $self->dict;
  
  $self->mt->render($self->sql, merge($vars, $self->vars));#%$vars ? %{$self->vars} ? merge($vars, $self->vars) : $vars : $self->vars
  
}

=pod

=encoding utf8

Доброго всем

=head1 DBIx::Mojo::Template

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

DBIx::Mojo::Template - Render SQL statements templates by Mojo::Template

=head1 VERSION

0.055

=head1 SYNOPSIS

  use DBIx::Mojo::Template;

  my $dict = DBIx::Mojo::Template->new(__PACKAGE__,mt=>{tag_start=>'%{', tag_end=>'%}',});
  
  my $sql = $dict->{'foo'}->render(table=>'foo', where=> 'where id=?');
  
  __DATA__
  @@ foo?cache=1
  %# my foo statement with prepare_cached (model sth)
  select *
  from {% $table %}
  {% $where %}


=head1 SUBROUTINES/METHODS

=head2 new

  my $dict = DBIx::Mojo::Template->new('Foo::Bar', vars=>{...}, mt=>{...})

where arguments:

=over 4

=item * $pkg (string)

Package name, where __DATA__ section SQL dictionary. Package must be loaded (use/require) before!

=item * vars (hashref)

Hashref of this dict templates variables. Vars can be merged when render - see L<#render>.

=item * mt (hashref)

For Mojo::Template object attributes. See L<Mojo::Template#ATTRIBUTES>.

  mt=>{ line_start=>'+', }

Defaults attrs:

  mt=> {vars => 1, prepend=>'no strict qw(vars); no warnings qw(uninitialized);',}

=back

=head2 singleton

Merge ditcs packages to one. Arguments same as L<#new>.

  DBIx::Mojo::Template->singleton('Foo');
  my $dict = DBIx::Mojo::Template->singleton('Bar');

=head2 render

Render template dict key.

  my $sql = $dict->render($key, var1=>..., var2 => ...,);

Each dict item is a object DBIx::Mojo::Statement with one method C<render>:

  my $sql = $dict->{'key foo'}->render(bar=>'baz', ...);

=head2 data

Same as L<#new> but returns unblessed hashref dict.

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/DBIx-Mojo-Template/issues>. Pull requests also welcome.


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Михаил Че (Mikhail Che).

This module is free software; you can redistribute it and/or modify it under the term of the Perl itself.


=cut

1; # End of DBIx::Mojo::Template
