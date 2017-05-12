package Csistck::Test::Template;

use 5.010;
use strict;
use warnings;

use base 'Csistck::Test::FileBase';
use Csistck::Oper qw/debug/;
use Csistck::Util qw/hash_file hash_string/;

our @EXPORT_OK = qw/template/;

use Template;
use File::Copy;
use Sys::Hostname::Long qw//;
use FindBin;
use Text::Diff ();

sub template { Csistck::Test::Template->new(@_); };

sub desc { sprintf("Template check for destination %s", shift->dest); }

sub file_check {
    my $self = shift;
    my $tplout;

    $self->template_file(\$tplout)
      or die("Template file not processed: template=<${\$self->src}>");
    
    my $hashsrc = hash_string($tplout);
    my $hashdst = hash_file($self->dest);
    
    return (defined $hashsrc and defined $hashdst and ($hashsrc eq $hashdst));
}

sub file_repair {
    my $self = shift;
    debug(sprintf("Output template: template=<%s> dest=<%s>",
      $self->src, $self->dest));
    # TODO tmp file for template
    open(my $h, '>', $self->dest)
      or die("Permission denied writing template");
    $self->template_file($h);
    close($h);
    return 1;
}

sub file_diff {
    my $self = shift;
    my $temp_h;
    # TODO prune args in common function
    $self->template_file(\$temp_h);
    say(Text::Diff::diff($self->dest, \$temp_h));
}

# Processing absoulte template name and outputs to reference
# variable $out. Die on error or unreadable template file
sub template_file {
    my ($self, $out) = @_;
    
    die("Invalid template name")
      unless($self->src =~ /^[A-Za-z0-9\-\_][A-Za-z0-9\/\-\_\.]+$/);
    
    # Build object, finish checks
    my $t = Template->new();
    my $file = get_absolute_template($self->src);
    $self->{hostname} = Sys::Hostname::Long::hostname_long();
    die("Template not found")
      if(! -e $file);
    die("Permission denied reading template")
      if(! -r $file);

    # Create Template object, no config for now
    open(my $h, $file);
    $t->process($h, $self, $out) or die $t->error();
    close($h);
}

# Get absoulte path from relative path
# TODO error checking
sub get_absolute_template {
    my $template = shift;
    return join "/", $FindBin::Bin, $template;
}

1;
__END__

=head1 NAME

Csistck::Test::Template - Csistck template check

=head1 DESCRIPTION

=head1 METHODS

=head2 template($target, :$src, :$uid, :$gid, :\&on_repair, [:ARGS])

Process file C<$src> as a Template Toolkit template, output to path C<$target>.
Optional named arguments can be used to alter the mode, uid, etc. All parameters
passed into the C<Csistck::Test::Template> object are available in the actual
template, so any additional named arguments are available in the template using
the argument's name -- these arguments should be hasrefs.

    role 'test' => template(
        '/etc/motd',
        src => 'sys/motd',
        foo => { bar => 1 },
        uid => 0,
        gid => 0,
        mode => '0640'
    );

This method takes the following named parameters, as well as additional
named parameters to be passed in to the template as variables:

=over

=item B<src>

Source file for template processing

=item B<mode>

Change targer file mode. This should be a string representation of the octal
mode of the target file -- eg. '0644'

=item B<uid>

Change target UID to the specified integer value.

=item B<gid>

Change target GID to the specified integer value.

=item B<on_repair>

If a repair operation is run, this coderef is called by the process method.

=back

Some arguments are automatically passed to the template processor:

=over

=item hostname

The full hostname of the current system

=back

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2012 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
