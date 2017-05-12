package CGI::MakeItStatic;

use strict;
use warnings ();
use IO::Scalar ();
use Cwd ();
use Carp ();
use overload '""' => sub { my($self) = @_; return $self->has_static ? 0 : $self };

our $VERSION = '0.03';

$| = 1;

sub check{
  my($class, $q, $attr) = @_;
  my $self = {};
  bless $self => $class;
  $attr ||= {};
  $attr->{dir} or Carp::croak('usage: CGI::MakeItStatic->check($q, {dir => "data_dir"})');
  $attr->{renew_key}   ||= "renew";
  $attr->{keys}        ||= [];
  $attr->{forbid}      ||= sub {return 0};
  $attr->{forbidrenew} ||= sub {return 0};
  $attr->{noprint}     ||= 0;
  $self->{attr}          = $attr;
  $self->{has_static}    = 0;
  $self->{output}        = '';
  return if ref $attr->{forbid} eq 'CODE' and $attr->{forbid}->($q);

  my $static_file = $self->_file_name($q);
  return unless $static_file;

  $self->has_static($self->_check($q, $static_file));
  return $self;
}

sub _check{
  my($self, $q, $static_file) = @_;
  my $attr = $self->attr;
  my $renew = $attr->{forbidrenew}->($q) ? 0 : $q->param($attr->{renew_key});
  if(not $renew and -e $static_file){
    # create new static file
    open my $in, "<", $static_file or die("cannot open file to read: " . $static_file);
    seek($in, 0, 0);
    local $/ = undef;
    my $text = <$in>;
    close $in;
    print $text unless $self->attr->{noprint};
    $self->{output} = $text;
    return 1;
  }else{
    my $data = "";
    $self->{stdout} =  IO::Scalar->new(\$data);
    $self->{static_file} = $static_file;
    $self->{original_select} = select();
    select($self->{stdout});
    return 0;
  }
}

sub _file_name{
  my($self, $q) = @_;
  my $attr = $self->attr;
  my @str;
  $attr->{dir} =~ s|/+|/|;
  my $file = Cwd::abs_path($0);
  my $name;
  if(ref(my $name_code = $attr->{name}) eq 'CODE'){
    $name = $q->escape($name_code->($q, $file));
  }else{
    foreach my $key (sort{$a cmp $b} (@{$attr->{keys}} || $q->param)){
      next if $key eq $attr->{renew_key};
      my @value = $q->param($key);
      foreach my $v (sort {$a cmp $b} @value){
        push @str, "$key=$v";
      }
    }
    return unless @str;
    $name = $q->escape($file . '?' . join "&", @str);
  }
  return $attr->{dir} . '/' . $name;
}

sub attr{ my $self = shift; @_ ? $self->{attr}->{shift()} : $self->{attr}}

sub has_static{ my $self = shift; return @_ ? $self->{has_static} = shift : $self->{has_static}; }

sub output{ my($self) = @_; return my $output = $self->{output}; }

sub end{ my($self) = @_; $self->DESTROY; }

sub DESTROY{
  my($self) = @_;
  unless($self->{destroy}++){
    my $s = $self->{stdout};
    if(ref $s){
      my $output = $s;
      die "no output" unless $output;
      open my $out, ">", $self->{static_file} or die "cannot open file to write: " . $self->{static_file};
      seek($out, 0,0);
      print $out $output;
      close $out;
      select($self->{original_select});
      print $output unless $self->attr->{noprint};
      $self->{output} = $output;
    }
  }
}

1;

__END__

=pod

=head1 NAME

CGI::MakeItStatic - not cache, to make cgi static

=head1 SYNOPSIS

  ### simple usage
  use CGI::MakeItStatic;

  my $q = new CGI;
  my $check = CGI::MakeItStatic->check($q, {dir => '/var/www/static'})
              or exit;

  # do something ...

  ### advanced usage
  use CGI::MakeItStatic;

  my $q = new CGI;
  my $check = CGI::MakeItStatic->check
    (
     $q,
     {
      dir => "/tmp/CGI-MakeItStatic",
      keys => [qw/month_ago/],
      # code to define static name
      name  =>
      sub
      {
        my($q) = @_;
        my($m, $y) = (localtime)[4, 5];
        $y += 1900; $m++;
        return sprintf("month_ago=%04d%02d", ($m -= $q->param('month_ago')) <= 0 ? ($y + int($m / 12) - 1, $m % 12 || 12) : ($y, $m));
      },
      # if month_ago > 2, won't recreate
      forbidrenew =>
      sub {
        my($q) = @_;
        return ($q->param('month_ago') > 2) or $q->param('month_ago') < 0;
      },
      # if month_ago > 10, not do special thing
      forbid =>
      sub {
        my($q) = @_;
        return $q->param('month_ago') > 10 or $q->param('month_ago') < 0;
      }
     }
    ) or exit;

  # do something ...

=head1 DESCRIPTION

CGI::MakeItStatic makes CGI program static. It is for not good CGI programs.
For examle, Here is the program which display some statistics for each month.
But it is no need to calculate past month statistics because it never be changed.
If it takes too much time to calcurate past month statistics, ... it is too bad.
CGI::MakeItStatic provides the simple way to make it static.

=head1 WORK FLOW

 1.create object
   - if static file exists, print it and return.
   - else
   -- hijack STDOUT
   -- define static file name
      normaly, CGI filename and escaped key=value&key=value...
 
 2. CGI do something
 
 3. output hijacked STDOUT to file and STDOUT

At first, construct CGI::MakeItStatic object with CGI object and some option.
You have to get the object. if you don't receive it, this doesn't work well at all.
In this timing, STDOUT is hijacked by CGI::MakeItStatic object and
it stores the result of CGI execution to variable.
Finaly, when the object is destroyed, it outputs variable contents to file and STDOUT.

=head1 CONSTRUCTOR USAGE

=over 4

=item check

  my $check = CGI::MakeItStatic->check($q, $attr) or exit;

$q is CGI object, $attr is hashref as constructor option.
if static file exists already, it returns 0 (but it is object).
Normaly, if 0 is returned, program should do exit.

If program don't exit, you should use 'noprint' option and use 'end' method at last.

=back

=head1 CONSTRACTOR OPTION

=over 4

=item dir = $directory

directory location to store static file.
Only this option is required.

=item keys = [qw/key1 key2/]

Normaly static file name is filename and all key value paris.
With this option, you can use only key(s) you want.

=item name = $code_ref

When you want your rule for static file name, use it.
$code_ref have to return name of static file name.
See SYNOPSIS second example.

The arguments of $code_ref are CGI object and filename.

=item forbid = $code_ref

If this code_ref returns 1, CGI::MakeItStatic do nothing.
See SYNOPSIS second example.

The Argument of $code_ref is CGI object.

=item forbidnew = $code_ref

If this code_ref return 1, CGI::MakeItStatic don't create static file,
even if renew key is true. See SYNOPSIS second example.

The Argument of $code_ref is CGI object.

=item renew = $key_name

If this key name is true, recreate static file.
'renew' is used as $key_name if you don't specify.

=item noprint = 1/0

If this value is true. CGI::MakeItStatic don't print static file content or hijacked STDOUT content.
You can get it from $obj->output. See output and end method.

=back

=head1 METHOD

=over 4

=item output

 $file_conent = $obj->output;

return the static file content or the hijacked STDOUT content.
This method have to be used after end method.

=item end

 $obj->end;

This does DESTROY. This module create static file when DESTROY is called,
so you want to use 'output' mehtod, you should use this method befor it.

=item has_static

 $obj->has_static;

If it returns true, the static file exists.

=back

=head1 NOTE

=over 4

=item It is like CGI::Cache

I think this module doing is neary same as CGI::Cache. But I don't consult its code.
So I will change this module like CGI::Cache if it is better than this.

=item mod_perl is OK?

I haven't test it.

=back

=head1 SOLUTION

You have heavy CGI program it is no need to update in realtime.
You can slove this problem as following.

write following in crontab;

 */10 * * * * (cd /path/to/working/directory; env REQUEST_METHOD=GET QUERY_STRING=renew=1&ym=latest ./filename > /dev/null)

mofidy your CGI;

 use CGI::MakeItStatic;

 my $q = new CGI;
 my $check = CGI::MakeItStatic->check($q, {dir => '/path/to/data', keys => 'ym'})
             or exit;

Only do it, cron create static file and your CGI get static file content and return it.

=head1 CAUTION

This module control STDOUT. If your CGI control STDOUT.
This may conflict with your program.

=head1 AUTHOR

Ktat, E<lt>atusi@pure.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
