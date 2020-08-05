
# This config file has been generated automatically on 17:25:00 31-Mar-2020.
# We advise not to modify directly this file manually but rather to modify
# the yaml-generator command instead for traceability and reproducibility.

yaml-generator-42.pl --run_mode=phylogenomic --out_suffix=-my-42-nuc-simple \
--queries test/MSAs/queries.idl \
--evalue=1e-05 --homologues_seg=yes --max_target_seqs=10000 --templates_seg=no \
--bank_dir test/candidates/genomes/ --bank_suffix=.nsq --bank_mapper test/candidates/genomes/nuc-bank-mapper.idm \
--ref_brh=on --ref_bank_dir test/ref_banks --ref_bank_suffix=.psq --ref_bank_mapper test/ref_banks/ref-bank-mapper.idm \
--ref_org_mul=0.66 --ref_score_mul=0.99 \
--trim_homologues=on --trim_max_shift=20000 --trim_extra_margin=15 \
--merge_orthologues=off \
--aligner_mode=exoblast --ali_skip_self=off --ali_cover_mul=1.1 --ali_keep_old_new_tags=off --ali_keep_lengthened_seqs=on \
--tax_reports=on \
--tax_min_score=0 --tax_score_mul=0 --tax_min_ident=0 --tax_min_len=0 \
--tol_check=off
