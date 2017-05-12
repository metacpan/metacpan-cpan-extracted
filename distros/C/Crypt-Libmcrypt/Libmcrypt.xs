#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mutils/mcrypt.h"

#include "const-c.inc"

MODULE = Crypt::Libmcrypt		PACKAGE = Crypt::Libmcrypt		

INCLUDE: const-xs.inc

const char *
mcrypt_check_version(arg0)
	const char *	arg0

int
mcrypt_enc_get_state(td, st, size)
	MCRYPT	td
	void *	st
	int *	size

int *
mcrypt_enc_get_supported_key_sizes(td, len)
	MCRYPT	td
	int *	len

int
mcrypt_enc_mode_has_iv(td)
	MCRYPT	td

int
mcrypt_enc_set_state(td, st, size)
	MCRYPT	td
	void *	st
	int	size

void
mcrypt_free(ptr)
	void *	ptr

void
mcrypt_free_p(p, size)
	char **	p
	int	size

int
mcrypt_generic(td, plaintext, len)
	MCRYPT	td
	void *	plaintext
	int	len

int
mcrypt_generic_deinit(td)
	MCRYPT	td

int
mcrypt_generic_end(td)
	MCRYPT	td

int
mcrypt_generic_init(td, key, lenofkey, iv)
	MCRYPT	td
	void *	key
	int	lenofkey
	void *	iv

int
mcrypt_module_algorithm_version(algorithm, a_directory)
	char *	algorithm
	char *	a_directory

int
mcrypt_module_close(td)
	MCRYPT	td

int
mcrypt_module_get_algo_block_size(algorithm, a_directory)
	char *	algorithm
	char *	a_directory

int
mcrypt_module_get_algo_key_size(algorithm, a_directory)
	char *	algorithm
	char *	a_directory

int *
mcrypt_module_get_algo_supported_key_sizes(algorithm, a_directory, len)
	char *	algorithm
	char *	a_directory
	int *	len

int
mcrypt_module_is_block_algorithm(algorithm, a_directory)
	char *	algorithm
	char *	a_directory

int
mcrypt_module_is_block_algorithm_mode(mode, m_directory)
	char *	mode
	char *	m_directory

int
mcrypt_module_is_block_mode(mode, m_directory)
	char *	mode
	char *	m_directory

int
mcrypt_module_mode_version(mode, a_directory)
	char *	mode
	char *	a_directory

MCRYPT
mcrypt_module_open(algorithm, a_directory, mode, m_directory)
	char *	algorithm
	char *	a_directory
	char *	mode
	char *	m_directory

int
mcrypt_module_self_test(algorithm, a_directory)
	char *	algorithm
	char *	a_directory

int
mcrypt_module_support_dynamic()

void
mcrypt_perror(err)
	int	err

const char *
mcrypt_strerror(err)
	int	err

int
mdecrypt_generic(td, plaintext, len)
	MCRYPT	td
	void *	plaintext
	int	len
