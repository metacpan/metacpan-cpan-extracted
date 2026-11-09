# Widen theme - give some characters a column of their own, for terminals
# that draw them over two columns on top of the next character (macOS).
# Add more in config.sh with widen_chars+=(CODE or FIRST-LAST).
widen_chars+=(
    2460-24FF   # circled digits
    1F5D1       # wastebasket
)
pass_md+=(--begin "&widen(chars=$(IFS=:; echo "${widen_chars[*]}"))")
