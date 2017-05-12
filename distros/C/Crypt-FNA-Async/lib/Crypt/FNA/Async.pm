# package: Anak Cryptography with Fractal Numerical Algorithm FNA
# author: Mario Rossano aka Anak, www.netlogicalab.com, www.netlogica.it; software@netlogicalab.com; software@netlogica.it
# birthday 05/08/1970; birthplace: Italy
# LIBRARY FILE

# Copyright (C) 2009,2010 Mario Rossano aka Anak
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either:
# CC-NC-BY-SA 
# license http://creativecommons.org/licenses/by-nc-sa/2.5/it/deed.en
# Creative Commons License: http://i.creativecommons.org/l/by-nc-sa/2.5/it/88x31.png
# FNA Fractal Numerical Algorithm for a new cryptography technology, author Mario Rossano
# is licensed under a: http://creativecommons.org/B/by-nc-sa/2.5/it/deed.en - Creative Commons Attribution-Noncommercial-Share Alike 2.5 Italy License
# Permissions beyond the scope of this license may be available at software@netlogicalab.com

package Crypt::FNA::Async;

# caricamento lib
	use strict;
	use warnings;

	our $can_use_FNA = eval 'use Crypt::FNA; 1';
	our $can_use_threads = eval 'use threads qw(yield); 1';
# fine caricamento lib

our $VERSION =  '0.10';

# metodi ed attributi

	sub new {
		my $class = shift;
		my $init  = shift;
		my $self={};

		bless $self,$class;
		
		$self->r($init->{r});
		$self->angle($init->{angle});
		$self->square($init->{square});
		$self->magic($init->{magic});
		$self->message($init->{message});
		$self->salted($init->{salted});
		
		return $self	
	}
	
		sub r {
			my $self=shift;
			if (@_) {
				$self->{r}=shift
			}
			return $self->{r}
		}
		sub angle {
			my $self=shift;
			if (@_) {
				$self->{angle}=shift
			}
			return $self->{angle}
		}
		sub square {
			my $self=shift;
			if (@_) {
				$self->{square}=shift
			}
			return $self->{square}
		}
		sub magic {
			my $self=shift;
			if (@_) {
				$self->{magic}=shift
			}
			return $self->{magic}
		}
		sub message {
			my $self=shift;
			if (@_) {
				$self->{message}=shift
			}
			return $self->{message}
		}
		sub salted {
			my $self=shift;
			if (@_) {
				$self->{salted}=shift
			}
			return $self->{salted}
		}

	sub encrypt_files {
		my $self=shift;
		my @files_to_encrypt=@_;

		#istanza oggetto FNA
		my $krypto;
		if ($can_use_FNA) {
			$krypto=$self->make_fna_object
		} else {
			push(@{$self->{message}},22);
			return
		}
		
		my @thr;
		
		# TRY
		if ($can_use_threads) {
			for (@files_to_encrypt) {
				push @thr,threads->new(sub
					{
						my $krypto=shift;
						my $file_to_encrypt=shift;
						my $file_encrypted=$file_to_encrypt.".fna";
						$krypto->encrypt_file($file_to_encrypt,$file_encrypted);
						threads->yield()
					},
					$krypto,
					$_
				);
			}
			for (@thr) {
				$_->join()
			}
		# CATCH
		} else {
			for (@files_to_encrypt) {
				$krypto->encrypt_file($_,$_.'.fna')
			}
		}

	}

	sub decrypt_files {
		my $self=shift;
		my @files_to_decrypt=@_;

		#istanza oggetto FNA
		my $krypto;
		if ($can_use_FNA) {
			$krypto=$self->make_fna_object
		} else {
			# aggiungere codice errore 22 che informa che fna non è installato
			push(@{$self->{message}},22);
			return
		}
	
		my @thr;
		
		# TRY
		if ($can_use_threads) {
			for (@files_to_decrypt) {
				push @thr,threads->new(sub
					{
						my $krypto=shift;
						my $file_to_decrypt=shift;
						my $file_decrypted=$file_to_decrypt;
						$file_decrypted=~ s/\.fna$//;
						$krypto->decrypt_file($file_to_decrypt,$file_decrypted);
						threads->yield()
					},
					$krypto,
					$_
				);
			}
			for (@thr) {
				$_->join()
			}
		# CATCH
		} else {
			for (@files_to_decrypt) {
				my $file_to_decrypt=$_;
				my $file_decrypted=$file_to_decrypt;
				$file_decrypted=~ s/\.fna$//;
				$krypto->decrypt_file($file_to_decrypt,$file_decrypted)
			}
		}
	}	

	sub make_fna_object {
		my $self=shift;
		my $krypto=Crypt::FNA->new(
			{
				r=> $self->r,
				angle =>  $self->angle,
				square => $self->square,
				magic => $self->magic,
				salted => $self->salted
			}
		);
		return $krypto
	}

# end metodi ed attributi

1;

# POD SECTION

=head1 NAME

Crypt::FNA::Async

=head1 VERSION

Version 0.10

=head1 DESCRIPTION

Crypt::FNA::Async allow you to parallel encrypt/decrypt on a multicore CPU (and/or hyperthreading CPU).
If threads are not supported, the computation will take place in a synchronous rather than asynchronous.
	

=head1 CONSTRUCTOR METHOD
  
    use Crypt::FNA::Async;
    
    my $krypto_async=Crypt::FNA::Async->new(
      {
        r=> '8',
        angle =>  [56,-187,215,64],
        square => 4096,
        magic => 2,
        salted => 'true'
      }
   );
   
   my $krypto_async=Crypt::FNA::Async->new();


=head2 ATTRIBUTE r

see attribute 'r' of Crypt::FNA

=head2 ATTRIBUTE angle

see attribute 'angle' of Crypt::FNA

=head2 ATTRIBUTE square

see attribute 'square' of Crypt::FNA

=head2 ATTRIBUTE magic

see attribute 'magic' of Crypt::FNA

=head2 ATTRIBUTE salted

see attribute 'salted' of Crypt::FNA

=head2 ATTRIBUTE message

see attribute 'message' of Crypt::FNA


=head1 METHODS


=head2 new

See CONSTRUCTOR METHOD


=head2 encrypt_files

This method encrypt the input plain files to output crypted files.
The syntax is:

  
  $krypto_async->encrypt_files($name_plain_file1, $name_plain_file2,...)
  

=head2 decrypt_files

This method decrypt the input crypted files in the output plain file.
The syntax is:

  
  $krypto_async->decrypt_files($name_encrypted_file1, $name_encrypted_file2,...)
  
=head2 make_fna_object

Internal use, make a fna object

=head1 AUTHOR

  Mario Rossano
  software@netlogicalab.com
  software@netlogica.it
  http://www.netlogicalab.com

=head1 BUGS

Please, send me your alerts to software@netlogica.it

=head1 SUPPORT

Write me :) software@netlogica.it


=head1 COPYRIGHT & LICENSE

Crypt::FNA::Async by Mario Rossano, http://www.netlogicalab.com

This pod text by Mario Rossano

Copyright (C) 2009 Mario Rossano aka Anak
birthday 05/08/1970; birthplace: Italy

This program is free software; you can redistribute it and/or modify it
under the terms of either:
CC-NC-BY-SA
license http://creativecommons.org/licenses/by-nc-sa/2.5/it/deed.en
Creative Commons License: http://i.creativecommons.org/l/by-nc-sa/2.5/it/88x31.png

FNA Fractal Numerical Algorithm for a new cryptography technology, author Mario Rossano
is licensed under a: http://creativecommons.org/B/by-nc-sa/2.5/it/deed.en - Creative Commons Attribution-Noncommercial-Share Alike 2.5 Italy License

Permissions beyond the scope of this license may be available at software@netlogicalab.com