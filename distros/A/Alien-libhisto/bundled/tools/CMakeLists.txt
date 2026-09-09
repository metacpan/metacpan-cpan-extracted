find_package(Threads REQUIRED)

add_library(histocli
    src/cli_common.c
    src/cli_opt.c
    src/cli_main.c
    src/cli_palette.c
    src/cmd_fill.c
    src/cmd_plot.c
    src/cmd_stats.c
    src/cmd_fit.c
    src/cmd_cmp.c
    src/cmd_top.c
    src/tui_term.c
    src/tui_engine.c
)

set_target_properties(histocli PROPERTIES
    OUTPUT_NAME "histocli"
    POSITION_INDEPENDENT_CODE ON
)

target_include_directories(histocli PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(histocli PUBLIC histo Threads::Threads)
if(UNIX AND NOT APPLE AND NOT ANDROID)
    find_library(RT_LIB rt)
    if(RT_LIB)
        target_link_libraries(histocli PUBLIC ${RT_LIB})
    endif()
endif()

add_executable(histo-cli
    src/main.c
)

set_target_properties(histo-cli PROPERTIES OUTPUT_NAME "histo")

target_include_directories(histo-cli PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(histo-cli PRIVATE histocli)

# Create aliases in build directory
set(TOOL_ALIASES histo-fill histo-plot histo-stats histo-fit histo-cmp histo-top)

if(WIN32)
    foreach(alias ${TOOL_ALIASES})
        add_custom_command(TARGET histo-cli POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:histo-cli> $<TARGET_FILE_DIR:histo-cli>/${alias}.exe
            COMMENT "Creating CLI alias copy ${alias}.exe -> histo.exe"
        )
    endforeach()
else()
    foreach(alias ${TOOL_ALIASES})
        add_custom_command(TARGET histo-cli POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE_NAME:histo-cli> ${CMAKE_CURRENT_BINARY_DIR}/${alias}
            COMMENT "Creating CLI alias symlink ${alias} -> histo"
        )
    endforeach()
endif()

install(TARGETS histocli histo-cli
    EXPORT libhistoTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

if(WIN32)
    foreach(alias ${TOOL_ALIASES})
        install(FILES $<TARGET_FILE:histo-cli>
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            RENAME ${alias}.exe
        )
    endforeach()
else()
    foreach(alias ${TOOL_ALIASES})
        install(CODE "
            execute_process(
                COMMAND \${CMAKE_COMMAND} -E create_symlink histo \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${alias}\"
            )
        ")
    endforeach()
endif()
