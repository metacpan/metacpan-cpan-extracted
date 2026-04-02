# ICD-10

Downloaded Jul-30-2025  
https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Publications/ICD10CM/2026/icd10cm-table%20and%20index-2026.zip  
Version date: 6/12/2025

```bash
unzip *zip
# produces: icd10cm-tabular-2026.xml
```

## Note
The dot is stripped from the ICD-10 code when generating the JSON mapping.

```bash
jq -Rn '
  [ inputs
    | split("\t")
    | select(length == 2)
    | (.[1] as $code
       | ($code | gsub("\\."; ""))  as $key
       | { ($key): .[0] })
  ]
  | add
' /media/mrueda/2TBS/CNAG/Project_ConvertPheno/databases/icd-10/2026/icd10_label_code.tsv > icd10.json
```

```bash
jq '
  to_entries
| sort_by(.key)
| map(.key)
| to_entries
| map({ key: .value, value: (.key + 1) })
| from_entries
' icd10.json > icd10_order.json
```
