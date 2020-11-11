decrypt-vault-files:
	ansible-vault decrypt group_vars/all/vault-ia.yml --vault-password-file vault-pass-ia.txt 
	ansible-vault decrypt group_vars/all/vault-tx.yml --vault-password-file vault-pass-tx.txt 

encrypt-vault-files:
	ansible-vault encrypt group_vars/all/vault-ia.yml --vault-password-file vault-pass-ia.txt 
	ansible-vault encrypt group_vars/all/vault-tx.yml --vault-password-file vault-pass-tx.txt 

dump-vars:
	ansible-playbook dump.yml --vault-password-file vault-pass-ia.txt --vault-password-file vault-pass-tx.txt 

