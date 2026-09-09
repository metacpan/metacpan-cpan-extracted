add_requires("nuklear 4.13.2")

target("nk_win")
    set_kind("shared")
    set_languages("c11")
    add_files("nk_win.c")
    add_includedirs(".")
    add_packages("nuklear")
    if is_plat("windows") then
        add_links("gdi32", "user32", "msimg32")
    elseif is_plat("linux", "macosx") then
        add_links("X11")          -- Xlib backend (macOS: assume XQuartz present)
        add_defines("_XOPEN_SOURCE=500")
    end