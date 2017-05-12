library("RCurl")
library("rjson")

results = tryCatch(
  fromJSON(
    postForm(
      "https://indra.mullins.microbiol.washington.edu/locate-sequence/within/hiv",
      sequence="SLYNTVAVLYYVHQR",
      sequence="TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG")),
  HTTPError = function(e) cat("Error making request: ", e$message),
  error = function(e) cat("Error decoding JSON"))

print(lapply(results, function(s) s$genome_start))
