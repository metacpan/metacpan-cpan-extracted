package App::sh2p::Trap;
# January 2009

use strict;

use App::sh2p::Handlers;
use App::sh2p::Utils;

our $VERSION = '0.06';

my %function_signals;
my %global_signals;

my %install_dtable   = (ERR  => \&install_ERR,
                        EXIT => \&install_EXIT);
my %uninstall_dtable = (ERR  => [\&uninstall_ERR]);

########################################################

########################################################
# Trap '' for IGNORE
# Trap -  for DEFAULT
# Q: What is the effect of EXIT with a function?

sub do_trap {
    my ($cmd, $handler, @sigs) = @_;
    my $ntok = 2;
    my $instat;
    
    #print STDERR "do_trap: handler: <$handler> sigs: <@sigs>\n";
    
    if ($handler ne '-' && $handler ne "''" && $handler ne '""') {
        # Store the handler
        $instat = new App::sh2p::Statement(); 
        $handler =~ s/^\'(.*)\'/$1/;      # Strip single quotes

        #print STDERR "Trap @sigs handler: <$handler>\n";
        $instat->tokenise ($handler);
        $instat->identify_tokens (0);
    }
    
    for my $sig (@sigs) {
    
        my $statement = $instat->copy();
        
        if ($handler eq '-') {
            if (defined $uninstall_dtable{$sig}[1]) {
                my $statement = pop @{$uninstall_dtable{$sig}};
                &{$uninstall_dtable{$sig}[0]}($statement);
                
                delete $function_signals{$sig} if ina_function();
            }
            else {
                iout ("\$SIG{'$sig'} = 'DEFAULT';\n");
            }       
        }
        elsif ($handler eq "''" || $handler eq '""') {
            if (defined $uninstall_dtable{$sig}[1]) {
	        my $statement = pop @{$uninstall_dtable{$sig}};
	        &{$uninstall_dtable{$sig}[0]}($statement);
	        
	        delete $function_signals{$sig} if ina_function();
	    }
	    else {
	        iout ("\$SIG{'$sig'} = 'IGNORE';\n");
            }      
        }
        else {
        
            if (exists $install_dtable{$sig}) {
                push @{$uninstall_dtable{$sig}}, $statement;
               
                &{$install_dtable{$sig}}($statement);
                
                # Hummm  should be have different dtables for each?
	        if (ina_function()) {
		    $function_signals{$sig} = undef;
                }
            }
            else {
                if ($sig eq 'DEBUG'  ||
                    $sig eq 'ERR'    ||
                    $sig eq 'RETURN' )    # Bash 3.0
                {
                   error_out ("Conversion for builtin trap $sig is not supported");
                }
                else {
                    install_general_handler($sig, $statement);
                }
            }
        }
        $ntok++;
    }
        
    return $ntok;
}

########################################################

sub uninstall_function_traps {

   #print STDERR "Trap::uninstall_function_traps <",keys %function_signals,">\n";
   
   for my $sig (keys %function_signals) {    

       my $statement = $uninstall_dtable{$sig}[1];
       &{$uninstall_dtable{$sig}[0]}($statement);
       
       delete $uninstall_dtable{$sig};
   }
   
   undef %function_signals;
}

########################################################

sub install_ERR {
    
    if (!ina_function()) {
        error_out ("No conversion routine for trap ERR outside a function");
        return;
    }

    error_out ("trap ERR converted to eval");
    iout ("eval {\n");
    inc_indent(); 
    inc_block_level();
}

sub uninstall_ERR {
    my ($handler) = @_;

    dec_block_level();
    dec_indent();
    iout "};    # eval\n";
    iout ("if (\$\@) {\n");
    inc_indent();
    inc_block_level();
       
    $handler->convert_tokens();
       
    dec_block_level();
    dec_indent();
    iout ("}\n");
}

#######################################################

sub install_EXIT {
    
    if (ina_function()) {
        error_out ("No conversion routine for trap EXIT inside a function");
        return;
    }

    my ($handler) = @_;
    my $buffer;
    
    out_to_buffer (\$buffer);
    error_out ("trap EXIT converted to END block");
    
    iout ("END {\n");
    inc_indent(); 
    inc_block_level();
    
    $handler->convert_tokens();
           
    dec_block_level();
    dec_indent();
    iout ("}\n");
    
    off_out_to_buffer();
    
    App::sh2p::Handlers::store_subs('END', $buffer);  
}

########################################################

sub install_general_handler {
    
    my ($sig, $handler) = @_;
    my $buffer;
    my $sub = "sh2p_${sig}_handler";
    
    error_out ("trap $sig calling $sub");
    iout ("\$SIG{'$sig'} = \\&$sub;\n");

    out_to_buffer (\$buffer);
    
    iout ("sub $sub {\n");
    inc_indent(); 
    inc_block_level();
    
    $handler->convert_tokens();
           
    dec_block_level();
    dec_indent();
    iout ("}\n");
    
    off_out_to_buffer();
    
    App::sh2p::Handlers::store_subs($sub, $buffer);  
}

########################################################

########################################################

1;

__END__
=head1 Summary
package App::sh2p::Trap;

=cut
