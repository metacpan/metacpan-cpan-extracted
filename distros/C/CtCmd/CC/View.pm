##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2011. All rights reserved.           #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# Matt Lennon - Creation and framework.                                  #
#                                                                        #
# William Spurlin - Maintenance and defect fixes                         #
#                                                                        #
##########################################################################

=head1 NAME

CC::View - XXX

=cut

##############################################################################
package CC::View;
##############################################################################

#
# wjs
#

@ISA = qw(ClearCase::CtCmd);

use CC::CC;
use CC::Stream;
# use Trace;
use strict;




##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class = shift;
    my $tag   = shift;
    chomp $tag;
    CC::CC::assert($tag);
    my $this  = { };
    my $cleartool = ClearCase::CtCmd->new;
    my $status;
    $this->{cleartool}=$cleartool;
    $this->{tag} = $tag;
    $this->{status}=$cleartool->status;
    return bless($this, $class);
}

##############################################################################
sub create
##############################################################################
{
    # my $trace();
    my %args   = @_;
    my $stream = $args{stream};
    my @opts;
    
    CC::CC::assert($args{tag});

    # Set up command.

    my $tag = sprintf("smoke.%s.%d", $args{tag}, $$);
    my $stg = sprintf("%s/%s.vws", $CC::CC::tmp_dir, $tag);

    $stream and push(@opts, '-stream', $stream->objsel());

    my @cmd = ('mkview', @opts, '-tag', $tag, $stg);

    my @out = ClearCase::CtCmd::exec(@cmd);
    print("$out[1] $tag"); # print the first line - "Created view ..."

    if( $out[0] ){
	return 0;
    }else{
	return new CC::View($tag);
    }
}

##############################################################################
sub current_view
##############################################################################
{
    # my $trace();

# wjs   
    my @output = ClearCase::CtCmd::exec('pwv', '-s');
    my $status = shift @output;
    my $tag    = shift @output;

    if ( $status ) {
        return 0;
    } else {
        return new CC::View($tag);
    }
}

##############################################################################
sub config_spec
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my $rv = $this->{cleartool}->exec('catcs', '-tag', $this->tag());
    $this->{status} = $this->{cleartool}->status;
    return $this->{cleartool}->status? 0 : $rv;
}

##############################################################################
sub set_config_spec
##############################################################################
{
    # my $trace();
    my $this  = shift;
    my $cspec = shift;
    my $tmpfile = "$CC::CC::tmp_dir/cs$$";
    my $st;

    open(TMPCS, ">$tmpfile") || die("Can't open temp file");
    print(TMPCS $cspec);
    close(TMPCS);

    $this->{cleartool}->exec('setcs', '-tag', $this->tag(), $tmpfile);

    unlink($tmpfile);
    return $this->{cleartool}->status? 0 : 1;
}

##############################################################################
sub is_ucm_view
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);
    
    my $out = $this->{cleartool}->exec('lsview', '-l', $this->tag());
    $this->{status} = $this->{cleartool}->status;
    return($out =~ /View attributes:.*ucmview/);
}

##############################################################################
sub stream
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);
    CC::CC::assert($this->is_ucm_view());
    
    my $objsel = $this->{cleartool}->exec('lsstream','-fmt','%Xn','-view', $this->tag());
    $this->{status} = $this->{cleartool}->status;
    return new CC::Stream($objsel);
}

##############################################################################
sub set_custom_element_rules
##############################################################################
{
    # my $trace();
    my $this         = shift @_;
    my $custom_rules = shift @_;
    my @old_cspec;
    my @new_cspec;
    my $line;
    my $in_custom_rules_section;

    @old_cspec = split("^", $this->config_spec());
    chomp(@old_cspec);

    $in_custom_rules_section = 0;

    foreach $line (@old_cspec) {

        if ($line =~ /#UCMCustomElemBegin/) {

            CC::CC::assert( ! $in_custom_rules_section);
            push(@new_cspec, $line, $custom_rules);
            $in_custom_rules_section = 1;

        } elsif ($line =~ /#UCMCustomElemEnd/) {
                 
            CC::CC::assert($in_custom_rules_section);
            push(@new_cspec, $line);
            $in_custom_rules_section = 0;

        } elsif ( ! $in_custom_rules_section) {

            push(@new_cspec, $line);
        }
    }

    $this->set_config_spec(join("\n", @new_cspec));

    return 1;
}

##############################################################################
sub DESTROY
##############################################################################
{
    return 1; # no-op
}

##############################################################################
sub tag
##############################################################################
{
    # my $trace();
    my $this  = shift;

    CC::CC::assert($this);

    return $this->{tag};
}

1;   # Make "use" and "require" happy









