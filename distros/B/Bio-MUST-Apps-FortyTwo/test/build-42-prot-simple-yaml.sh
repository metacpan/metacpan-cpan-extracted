
# This config file has been generated automatically on 15:05:54 10-Jan-2019.
# We advise not to modify directly this file manually but rather to modify
# the yaml-generator command instead for traceability and reproducibility.

yaml-generator-42.pl --run_mode=phylogenomic --out_suffix=-42-prot-simple \
--queries=MSAs/queries.idl \
--evalue=1e-05 --homologues_seg=yes --max_target_seqs=10000 --templates_seg=no \
--bank_dir candidates/proteomes/ --bank_suffix=.psq --bank_mapper=candidates/proteomes/prot-bank-mapper.idm \
--ref_brh_mode=on --ref_bank_dir ref_banks --ref_bank_suffix=.psq --ref_bank_mapper=ref_banks/ref-bank-mapper.idm \
--ref_org_mul=0.66 --ref_score_mul=0.99 \
--trimming_mode=off \
--ls_action=keep --aligner_mode=blast --ali_patch_mode=off --ali_cover_mul=1.1 \
--tax_reports=on \
--best_hit \


