package DBIx::Mojo::Template;
use Mojo::Base -base;
use Mojo::Loader qw(data_section);
use Mojo::Template;
use Mojo::URL;
use Mojo::Util qw(url_unescape b64_decode class_to_path);#
use Mojo::File;
use Scalar::Util 'weaken';

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
  my $dict = {};
  my $data = data_section($pkg) || {};
  my $extra = $class->_data_dict_files($pkg => @{$arg{data} || []});
    #~ if ref($arg{data}) eq 'ARRAY';#$pkg ne 'main' && 
  #~ @$data{keys %$extra} = values %$extra
    #~ if ref($extra) eq 'HASH';
  #prio: near over far
  @$extra{keys %$data} = values %$data;
  
  while ( my ($k, $t) = each %$extra)  {
    my $url = Mojo::URL->new($k);
    my ($name, $param) = (url_unescape($url->path), $url->query->to_hash);
    utf8::decode($name);
    $dict->{$name} = DBIx::Mojo::Statement->new(dict=>$dict, name=>$name, raw=>$t, param=>$param, mt=>_mt(%{$arg{mt} || {}}), vars=>$arg{vars} || {});
    weaken $dict->{$name}->{dict};
  }
  die "None DATA dict in package [$pkg]"
    unless %$dict;
  return $dict;
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

# можно задать для модуля доп файлы словаря
# $self->_data_dict_files('Foo::Bar'=>'Bar.pm.dict.sql')
# на входе модуль и список имен доп файлов ОТНОСИТЕЛЬНО папки модуля
# @return hashref dict
sub _data_dict_files {
  my ($self, $pkg, @files) = @_;
  #~ require Module::Path;
  #~ Module::Path->import('module_path');module_path($pkg)
  my $dir = Mojo::File->new($INC{class_to_path($pkg)} || '.')->dirname;## 
  my $dict = {};
  for my $file (@files) {
    my $path = Mojo::File->new($file);
    $path = $dir->child($file)
      unless $path->is_abs;
    next unless -f $path && -r _;
    
    my $data = $path->slurp;
    utf8::decode($data);
    
    ## copy-paste from Mojo::Loader
    # Ignore everything before __DATA__ (some versions seek to start of file)
    $data =~ s/^.*\n__DATA__\r?\n/\n/s;
 
    # Ignore everything after __END__
    $data =~ s/\n__END__\r?\n.*$/\n/s;
 
    # Split files
    (undef, my @f) = split /^@@\s*(.+?)\s*\r?\n/m, $data;
 
    # Find data
    while (@f) {
      my ($name, $data) = splice @f, 0, 2;
      $dict->{$name} = $name =~ s/\s*\(\s*base64\s*\)$// ? b64_decode($data) : $data;
    }
  }
  return $dict;
}

our $VERSION = '0.060';

#=============================================
package DBIx::Mojo::Statement;
#=============================================
use Mojo::Base -base;
use Hash::Merge qw(merge);
use Scalar::Util 'weaken';

has [qw(dict name raw param mt vars sth)];
# sth - attr for save cached dbi statement

use overload '""' => sub { shift->raw };

sub template { shift->render(@_) }

sub render {
  my $self = shift;
  my $vars =ref $_[0] ? shift : { @_ };
  my $merge = merge($vars, $self->vars);
  $merge->{dict} ||= $self->dict;
  $merge->{DICT} = $self->dict;
  $merge->{st} = $self;
  weaken $merge->{st};
  
  $self->mt->render($self->raw, $merge);#%$vars ? %{$self->vars} ? merge($vars, $self->vars) : $vars : $self->vars
  
}

=pod

=encoding utf8

Доброго всем

=head1 DBIx::Mojo::Template

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

DBIx::Mojo::Template - Render SQL statements by Mojo::Template

=head1 VERSION

0.060

=head1 SYNOPSIS

  use DBIx::Mojo::Template;

  my $dict = DBIx::Mojo::Template->new(__PACKAGE__,mt=>{tag_start=>'%{', tag_end=>'%}',});
  
  my $sql = $dict->{'foo'}->render(table=>'foo', where=> 'where id=?');
  # or same
  my $sql = $dict->render('bar', where=> 'where id=?');
  
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

Defaults <mt> attrs:

  mt=> {vars => 1, prepend=>'no strict qw(vars); no warnings qw(uninitialized);',}

=item * data (arrayref) - optional

Define extra data files for dictionary. Absolute or relative to path of the module $pkg file point.

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
