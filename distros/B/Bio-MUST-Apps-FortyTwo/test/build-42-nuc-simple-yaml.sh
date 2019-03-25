
# This config file has been generated automatically on 15:54:37 10-Jan-2019.
# We advise not to modify directly this file manually but rather to modify
# the yaml-generator command instead for traceability and reproducibility.

yaml-generator-42.pl --run_mode=phylogenomic --out_suffix=-42-nuc-simple \
--queries=MSAs/queries.idl \
--evalue=1e-05 --homologues_seg=yes --max_target_seqs=10000 --templates_seg=no \
--bank_dir candidates/genomes/ --bank_suffix=.nsq --bank_mapper=candidates/genomes/nuc-bank-mapper.idm \
--ref_brh_mode=on --ref_bank_dir ref_banks --ref_bank_suffix=.psq --ref_bank_mapper=ref_banks/ref-bank-mapper.idm \
--ref_org_mul=0.66 --ref_score_mul=0.99 \
--trimming_mode=on --trim_max_shift=20000 --trim_extra_margin=15 \
--ls_action=keep --aligner_mode=exoblast --ali_patch_mode=off --ali_cover_mul=1.1 \
--tax_reports=on \



